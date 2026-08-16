/**
 * ECO Wallet — Merchant Payment Routes
 * 
 * POST /api/merchant/register           — Register a merchant (admin only)
 * POST /api/merchant/create-payment     — Billing software creates a payment request
 * GET  /api/merchant/payment/:id/status — Check payment status (fallback polling)
 * POST /api/merchant/pay                — Customer pays a pending merchant payment
 * GET  /api/merchant/payments           — List all payments for a merchant
 */
const express = require("express");
const { body, validationResult } = require("express-validator");
const mongoose = require("mongoose");
const crypto = require("crypto");
const bcrypt = require("bcryptjs");

const { protect, requireAdmin } = require("../middleware/auth");
const { merchantAuth } = require("../middleware/merchantAuth");
const Merchant = require("../models/Merchant");
const MerchantPayment = require("../models/MerchantPayment");
const User = require("../models/User");
const Transaction = require("../models/Transaction");
const { generateMerchantId, generatePaymentId, generateTransactionId } = require("../utils/idGenerator");
const { deliverWebhook } = require("../utils/webhookService");
const { auditLog } = require("../utils/logger");
const { notify } = require("../utils/notificationService");

const router = express.Router();

// ─── Default payment expiry (15 minutes) ─────────────────
// Public Merchant Onboarding Route (App login/signup sync to MongoDB Atlas)
router.post("/onboard", async (req, res) => {
  try {
    const { mobile_number, shop_name, owner_name, security_pin, api_key, merchant_id } = req.body;
    const phone = mobile_number;
    const mchId = merchant_id || `mch_${phone}`;
    const bName = shop_name;
    const oName = owner_name;

    let user = await User.findOne({ phone });
    if (!user) {
      user = await User.findOne({ user_id: mchId });
    }

    if (!user) {
      const passwordHash = await bcrypt.hash("EcoWallet2026!", 10);
      user = await User.create({
        user_id: mchId,
        name: oName,
        email: `${phone}@ecowallet.io`,
        phone: phone,
        password: passwordHash,
        balance: 1000,
        role: "user",
      });
    } else {
      user.name = oName;
      await user.save();
    }

    let merchant = await Merchant.findOne({ merchant_id: mchId });
    if (!merchant) {
      const apiKeyHash = await bcrypt.hash(api_key || `key_mch_${phone}_auto`, 10);
      merchant = await Merchant.create({
        merchant_id: mchId,
        user_id: user.user_id,
        business_name: bName,
        webhook_url: "http://localhost:5001/api/webhook",
        webhook_secret: `whsec_auto_${phone}`,
        api_key_hash: apiKeyHash,
        is_active: true,
      });
    } else {
      merchant.business_name = bName;
      await merchant.save();
    }

    res.json({
      success: true,
      message: "Merchant account onboarded to MongoDB Atlas successfully!",
      merchant: {
        merchant_id: merchant.merchant_id,
        user_id: merchant.user_id,
        business_name: merchant.business_name,
      },
    });
  } catch (error) {
    console.error("Merchant onboard error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post(
  "/register",
  protect,
  requireAdmin,
  [
    body("user_id").trim().notEmpty().withMessage("User ID of the shop owner is required"),
    body("business_name").trim().isLength({ min: 2, max: 200 }).withMessage("Business name must be 2-200 characters"),
    body("webhook_url").trim().isURL().withMessage("Valid webhook URL is required"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { user_id, business_name, webhook_url } = req.body;

      // Verify the user exists
      const shopOwner = await User.findOne({ user_id });
      if (!shopOwner) {
        return res.status(404).json({
          success: false,
          message: "User not found. The shop owner must have an ECO Wallet account.",
        });
      }

      // Check if merchant already registered for this user
      const existing = await Merchant.findOne({ user_id });
      if (existing) {
        return res.status(400).json({
          success: false,
          message: "A merchant is already registered for this user",
        });
      }

      // Generate credentials
      const merchant_id = generateMerchantId();
      const apiKey = `eco_mrc_${crypto.randomBytes(32).toString("hex")}`;
      const webhookSecret = `whsec_${crypto.randomBytes(32).toString("hex")}`;

      // Hash the API key for storage
      const salt = await bcrypt.genSalt(12);
      const api_key_hash = await bcrypt.hash(apiKey, salt);

      // Create merchant
      const merchant = await Merchant.create({
        merchant_id,
        user_id,
        business_name,
        webhook_url,
        webhook_secret: webhookSecret,
        api_key_hash,
        is_active: true,
      });

      await auditLog(
        "MERCHANT_REGISTER",
        req.user.user_id,
        `Merchant registered: ${business_name} (${merchant_id}) for user ${user_id}`,
        { merchant_id },
        req.ip,
        "admin"
      );

      // Return credentials — these are shown ONLY ONCE
      res.status(201).json({
        success: true,
        message: "Merchant registered successfully. Save these credentials — they will NOT be shown again.",
        data: {
          merchant: merchant.toPublic(),
          api_key: apiKey,
          webhook_secret: webhookSecret,
        },
      });
    } catch (error) {
      console.error("Merchant register error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);


router.post(
  "/create-payment",
  merchantAuth,
  [
    body("order_id").trim().notEmpty().withMessage("Order/bill ID is required"),
    body("amount").isFloat({ gt: 0, max: 50000 }).withMessage("Amount must be 0.01 - 50,000 ECO"),
    body("description").optional().trim().isLength({ max: 500 }).withMessage("Description max 500 chars"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { order_id, amount, description } = req.body;
      const merchant = req.merchant;

      // Check for duplicate order_id for this merchant (idempotency)
      const existingPayment = await MerchantPayment.findOne({
        merchant_id: merchant.merchant_id,
        order_id,
        status: { $in: ["pending", "completed"] },
      });

      if (existingPayment) {
        // Return existing payment instead of creating duplicate
        return res.json({
          success: true,
          message: existingPayment.status === "completed"
            ? "This order has already been paid"
            : "Payment request already exists",
          data: {
            payment_id: existingPayment.payment_id,
            order_id: existingPayment.order_id,
            amount: existingPayment.amount,
            status: existingPayment.status,
            qr_data: `eco://pay/${existingPayment.payment_id}?amount=${existingPayment.amount}&merchant=${merchant.merchant_id}`,
            expires_at: existingPayment.expires_at,
            completed_at: existingPayment.completed_at,
          },
        });
      }

      // Create payment request
      const payment_id = generatePaymentId();
      const expires_at = new Date(Date.now() + PAYMENT_EXPIRY_MINUTES * 60 * 1000);

      const payment = await MerchantPayment.create({
        payment_id,
        merchant_id: merchant.merchant_id,
        order_id,
        amount: parseFloat(amount),
        description: description || null,
        status: "pending",
        expires_at,
      });

      // QR data that the customer's app will scan
      const qr_data = `eco://pay/${payment_id}?amount=${payment.amount}&merchant=${merchant.merchant_id}`;

      res.status(201).json({
        success: true,
        message: "Payment request created",
        data: {
          payment_id,
          order_id,
          amount: payment.amount,
          description: payment.description,
          status: "pending",
          qr_data,
          expires_at,
        },
      });
    } catch (error) {
      console.error("Create payment error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);

/**
 * @route   GET /api/merchant/payment/:payment_id/status
 * @desc    Check payment status (polling fallback for billing software)
 * @auth    X-API-Key header
 */
router.get("/payment/:payment_id/status", merchantAuth, async (req, res) => {
  try {
    const payment = await MerchantPayment.findOne({
      payment_id: req.params.payment_id,
      merchant_id: req.merchant.merchant_id,
    }).lean();

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: "Payment not found",
      });
    }

    // Auto-expire if still pending and past expiry
    if (payment.status === "pending" && new Date() > new Date(payment.expires_at)) {
      await MerchantPayment.findOneAndUpdate(
        { payment_id: payment.payment_id, status: "pending" },
        { $set: { status: "expired" } }
      );
      payment.status = "expired";
    }

    res.json({
      success: true,
      data: {
        payment_id: payment.payment_id,
        order_id: payment.order_id,
        amount: payment.amount,
        status: payment.status,
        payer_id: payment.payer_id,
        payer_name: payment.payer_name,
        transaction_id: payment.transaction_id,
        completed_at: payment.completed_at,
        expires_at: payment.expires_at,
        webhook_delivered: payment.webhook_delivered,
      },
    });
  } catch (error) {
    console.error("Payment status error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/merchant/payments
 * @desc    List all payments for this merchant (with pagination)
 * @auth    X-API-Key header
 * @query   status=pending|completed|expired|failed  page=1  limit=20
 */
router.get("/payments", merchantAuth, async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const query = { merchant_id: req.merchant.merchant_id };
    if (status) query.status = status;

    const [payments, total] = await Promise.all([
      MerchantPayment.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      MerchantPayment.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: {
        payments,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error("List payments error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ═══════════════════════════════════════════════════════════
// CUSTOMER PAYMENT (JWT auth — from ECO Wallet app)
// ═══════════════════════════════════════════════════════════

/**
 * @route   POST /api/merchant/pay
 * @desc    Customer pays a pending merchant payment
 * @auth    JWT Bearer token (customer)
 * @body    { payment_id, pin? }
 * 
 * Flow:
 * 1. Validate the payment exists and is pending + not expired
 * 2. Debit customer, credit merchant's user account (atomic)
 * 3. Create a Transaction record
 * 4. Update MerchantPayment status → completed
 * 5. Fire webhook to billing backend
 * 6. Notify both customer and merchant
 */
router.post(
  "/pay",
  protect,
  [
    body("payment_id").trim().notEmpty().withMessage("Payment ID is required"),
    body("pin").optional().matches(/^\d{6}$/).withMessage("PIN must be exactly 6 digits"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { payment_id } = req.body;
      const customer_id = req.user.user_id;

      // 1. Find the payment
      const payment = await MerchantPayment.findOne({ payment_id });
      if (!payment) {
        return res.status(404).json({ success: false, message: "Payment not found" });
      }

      // Check status
      if (payment.status === "completed") {
        return res.status(400).json({ success: false, message: "This payment has already been completed" });
      }
      if (payment.status === "expired" || new Date() > payment.expires_at) {
        // Mark as expired if not already
        if (payment.status !== "expired") {
          await MerchantPayment.findOneAndUpdate(
            { payment_id, status: "pending" },
            { $set: { status: "expired" } }
          );
        }
        return res.status(400).json({ success: false, message: "This payment has expired" });
      }
      if (payment.status !== "pending") {
        return res.status(400).json({ success: false, message: `Payment is ${payment.status}` });
      }

      // 2. Find merchant and merchant's user account
      const merchant = await Merchant.findOne({ merchant_id: payment.merchant_id });
      if (!merchant || !merchant.is_active) {
        return res.status(400).json({ success: false, message: "Merchant is not active" });
      }

      // Prevent paying yourself
      if (customer_id === merchant.user_id) {
        return res.status(400).json({ success: false, message: "Cannot pay your own merchant account" });
      }

      const session = await mongoose.startSession();
      session.startTransaction();

      try {
        const claimPayment = await MerchantPayment.findOneAndUpdate(
          {
            payment_id,
            status: "pending",
            expires_at: { $gt: new Date() },
          },
          {
            $set: {
              status: "processing",
              payer_id: customer_id,
              payer_name: req.user.name,
              updatedAt: new Date(),
            },
          },
          { session, new: true }
        );

        if (!claimPayment) {
          const currentCheck = await MerchantPayment.findOne({ payment_id });
          if (currentCheck && currentCheck.status === "completed") {
            throw {
              status: 409,
              message: "This payment QR has already been completed by another user. Payment blocked.",
            };
          }
          throw {
            status: 410,
            message: "This payment QR has expired or is invalid. Please request a new QR from the merchant.",
          };
        }

        const customer = await User.findOne({ user_id: customer_id }).session(session);
        const merchantUser = await User.findOne({ user_id: merchant.user_id }).session(session);

        if (!customer) throw { status: 404, message: "Customer account not found" };
        if (!merchantUser) throw { status: 404, message: "Merchant account not found" };

        if (customer.balance < payment.amount) {
          throw { status: 400, message: "Insufficient balance in ECO Wallet" };
        }

        if (customer.pin && req.body.pin) {
          const pinMatch = await customer.matchPin(req.body.pin);
          if (!pinMatch) throw { status: 401, message: "Invalid payment PIN" };
        } else if (customer.pin && !req.body.pin) {
          throw { status: 400, message: "Payment PIN required" };
        }

        const debit = await User.findOneAndUpdate(
          { user_id: customer_id, version: customer.version },
          {
            $inc: { balance: -payment.amount, version: 1 },
            $set: { updatedAt: new Date() },
          },
          { session, new: true }
        );

        if (!debit) {
          throw { status: 409, message: "Concurrent transaction conflict — please retry" };
        }

        await User.findOneAndUpdate(
          { user_id: merchant.user_id },
          {
            $inc: { balance: payment.amount, version: 1 },
            $set: { updatedAt: new Date() },
          },
          { session }
        );

        const txn_id = generateTransactionId();
        await Transaction.create(
          [
            {
              transaction_id: txn_id,
              sender_id: customer_id,
              receiver_id: merchant.user_id,
              amount: payment.amount,
              type: "transfer",
              status: "success",
              description: payment.description || `Payment to ${merchant.business_name}`,
              sender_name: customer.name,
              receiver_name: merchantUser.name,
              timestamp: new Date(),
            },
          ],
          { session }
        );

        await MerchantPayment.findOneAndUpdate(
          { payment_id, status: "processing" },
          {
            $set: {
              status: "completed",
              payer_id: customer_id,
              payer_name: customer.name,
              transaction_id: txn_id,
              completed_at: new Date(),
            },
          },
          { session }
        );

        await Merchant.findOneAndUpdate(
          { merchant_id: merchant.merchant_id },
          {
            $inc: { total_payments: 1, total_revenue: payment.amount },
          },
          { session }
        );

        await session.commitTransaction();
        session.endSession();

        // 4. Reload the updated payment for webhook
        const updatedPayment = await MerchantPayment.findOne({ payment_id });

        // 5. Deliver webhook (fire-and-forget — don't block response)
        deliverWebhook(merchant, updatedPayment, "payment.completed").catch((err) => {
          console.error("Webhook delivery background error:", err);
        });

        // 6. Notifications
        await notify(
          customer_id,
          "transaction",
          "Payment Successful ",
          `You paid ${payment.amount} ECO to ${merchant.business_name}`,
          { transaction_id: txn_id, payment_id }
        );
        await notify(
          merchant.user_id,
          "transaction",
          "Payment Received ",
          `${customer.name} paid ${payment.amount} ECO (Order: ${payment.order_id})`,
          { transaction_id: txn_id, payment_id }
        );

        await auditLog(
          "MERCHANT_PAYMENT",
          customer_id,
          `${customer_id} → ${merchant.merchant_id}: ${payment.amount} ECO (Order: ${payment.order_id})`,
          { payment_id, transaction_id: txn_id, amount: payment.amount },
          req.ip
        );

        res.json({
          success: true,
          message: "Payment successful",
          data: {
            payment_id,
            transaction_id: txn_id,
            amount: payment.amount,
            merchant_name: merchant.business_name,
            new_balance: debit.balance,
            completed_at: updatedPayment.completed_at,
          },
        });
      } catch (error) {
        await session.abortTransaction();
        session.endSession();
        throw error;
      }
    } catch (error) {
      const status = error.status || 500;
      const message = error.message || "Payment failed";
      res.status(status).json({ success: false, message });
    }
  }
);

router.post(
  "/refund",
  protect,
  [
    body("payment_id").optional().trim(),
    body("transaction_id").optional().trim(),
    body("order_id").optional().trim(),
    body("amount").optional().isFloat({ gt: 0 }),
    body("reason").optional().trim(),
  ],
  async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      const { payment_id, transaction_id, order_id, amount, reason } = req.body;
      const callerUserId = req.user.user_id;

      if (!payment_id && !transaction_id && !order_id) {
        throw { status: 400, message: "Provide payment_id, transaction_id, or order_id to process refund." };
      }

      const query = {};
      if (payment_id) query.payment_id = payment_id;
      else if (transaction_id) query.transaction_id = transaction_id;
      else if (order_id) query.order_id = order_id;

      const payment = await MerchantPayment.findOne(query).session(session);
      if (!payment) {
        throw { status: 404, message: "Original payment record not found." };
      }

      if (payment.status !== "completed" && payment.status !== "partially_refunded") {
        throw { status: 400, message: `Cannot refund payment with status '${payment.status}'. Only completed payments can be refunded.` };
      }

      const merchant = await Merchant.findOne({ merchant_id: payment.merchant_id }).session(session);
      if (!merchant) {
        throw { status: 404, message: "Merchant not found for this payment." };
      }

      const isMerchantOwner = callerUserId === merchant.user_id;
      const isAdmin = req.user.role === "admin";
      if (!isMerchantOwner && !isAdmin) {
        throw { status: 403, message: "Unauthorized. Only the merchant or admin can initiate refunds." };
      }

      const currentRefunded = Number(payment.refunded_amount || 0);
      const remainingRefundable = Math.max(0, payment.amount - currentRefunded);
      if (remainingRefundable <= 0) {
        throw { status: 400, message: "This payment has already been fully refunded." };
      }

      const refundAmount = amount ? Math.min(Number(amount), remainingRefundable) : remainingRefundable;
      if (refundAmount <= 0) {
        throw { status: 400, message: "Invalid refund amount." };
      }

      const merchantUser = await User.findOne({ user_id: merchant.user_id }).session(session);
      const customer = await User.findOne({ user_id: payment.payer_id }).session(session);

      if (!merchantUser) throw { status: 404, message: "Merchant user account not found." };
      if (!customer) throw { status: 404, message: "Original payer user account not found." };

      if (merchantUser.balance < refundAmount) {
        throw { status: 400, message: `Merchant has insufficient wallet balance (${merchantUser.balance.toFixed(2)} ECO) to cover refund of ${refundAmount.toFixed(2)} ECO.` };
      }

      const debitMerchant = await User.findOneAndUpdate(
        { user_id: merchant.user_id, balance: { $gte: refundAmount } },
        { $inc: { balance: -refundAmount, version: 1 }, $set: { updatedAt: new Date() } },
        { session, new: true }
      );
      if (!debitMerchant) throw { status: 409, message: "Merchant balance conflict during refund." };

      const creditCustomer = await User.findOneAndUpdate(
        { user_id: customer.user_id },
        { $inc: { balance: refundAmount, version: 1 }, $set: { updatedAt: new Date() } },
        { session, new: true }
      );
      if (!creditCustomer) throw { status: 500, message: "Failed to credit customer refund." };

      const refundId = `REF_${Date.now()}`;
      const newTotalRefunded = currentRefunded + refundAmount;
      const newStatus = newTotalRefunded >= payment.amount ? "refunded" : "partially_refunded";
      const newRefundStatus = newTotalRefunded >= payment.amount ? "full" : "partial";

      await MerchantPayment.findOneAndUpdate(
        { payment_id: payment.payment_id },
        {
          $set: {
            status: newStatus,
            refund_status: newRefundStatus,
            refunded_amount: newTotalRefunded,
          },
          $push: {
            refund_history: {
              refund_id: refundId,
              amount: refundAmount,
              reason: reason || "Merchant initiated refund",
              created_at: new Date(),
            }
          }
        },
        { session }
      );

      await Transaction.create(
        [
          {
            transaction_id: refundId,
            sender_id: merchant.user_id,
            receiver_id: customer.user_id,
            amount: refundAmount,
            type: "transfer",
            status: "success",
            description: `Refund for Order #${payment.order_id} (${reason || "Customer refund"})`,
            sender_name: merchant.business_name,
            receiver_name: customer.name,
            timestamp: new Date(),
          }
        ],
        { session }
      );

      await session.commitTransaction();
      session.endSession();

      deliverWebhook(merchant, { ...payment.toObject(), refund_id: refundId, refund_amount: refundAmount, status: newStatus }, "payment.refunded").catch(() => { });

      try {
        await notify(customer.user_id, "transaction", "Refund Processed", `You received a refund of ${refundAmount} ECO from ${merchant.business_name}`, { refund_id: refundId });
        await notify(merchant.user_id, "transaction", "Refund Issued", `Refund of ${refundAmount} ECO issued to ${customer.name}`, { refund_id: refundId });
      } catch (_) { }

      res.json({
        success: true,
        message: `Refund of ${refundAmount} ECO processed successfully.`,
        data: {
          refund_id: refundId,
          payment_id: payment.payment_id,
          order_id: payment.order_id,
          refunded_amount: refundAmount,
          total_refunded: newTotalRefunded,
          status: newStatus,
          customer_new_balance: creditCustomer.balance,
        }
      });
    } catch (err) {
      await session.abortTransaction();
      session.endSession();
      const status = err.status || 500;
      res.status(status).json({ success: false, message: err.message || "Refund processing failed." });
    }
  }
);

/**
 * @route   GET /api/merchant/invoice/:bill_id
 * @desc    Public downloadable invoice webpage for customer QR scan
 */
router.get("/invoice/:bill_id", async (req, res) => {
  try {
    const { bill_id } = req.params;
    const cleanBillId = bill_id ? bill_id.trim() : "";
    const payment = await MerchantPayment.findOne({
      $or: [
        { payment_id: cleanBillId },
        { order_id: cleanBillId },
        { payment_id: `BILL_${cleanBillId}` },
        { order_id: `BILL_${cleanBillId}` },
      ]
    }).lean();

    let merchant = null;
    if (payment && payment.merchant_id) {
      merchant = await Merchant.findOne({
        $or: [{ merchant_id: payment.merchant_id }, { user_id: payment.merchant_id }]
      }).lean();
    }

    const shopName = req.query.shop_name || (payment && payment.shop_name) || (merchant ? merchant.business_name : "Dukaan Dost Retail Store");
    const ownerName = req.query.owner_name || (payment && payment.owner_name) || (merchant ? merchant.owner_name : "");
    const shopPhone = req.query.phone || req.query.shop_phone || (payment && payment.shop_phone) || (merchant ? merchant.mobile_number : "+91 98765 43210");
    const shopAddress = req.query.address || req.query.shop_address || (payment && payment.shop_address) || (merchant && merchant.address ? merchant.address : "Market Area, Main Road, India");
    const shopGstin = req.query.gstin || req.query.shop_gstin || (payment && payment.shop_gstin) || (merchant && merchant.gstin ? merchant.gstin : "");
    const amount = payment ? payment.amount : 0;
    const orderId = payment ? payment.order_id : cleanBillId;
    const payerName = payment ? (payment.payer_name || "Counter Customer") : "Valued Customer";
    const dateStr = payment && payment.completed_at ? new Date(payment.completed_at).toLocaleString("en-IN") : new Date().toLocaleString("en-IN");
    const statusStr = payment ? payment.status.toUpperCase() : "COMPLETED";

    const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tax Invoice - ${orderId}</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #F3F4F6; color: #111827; margin: 0; padding: 16px; display: flex; flex-direction: column; align-items: center; }
    .container { max-width: 540px; width: 100%; margin: 10px auto; }
    .actions { display: flex; gap: 10px; margin-bottom: 16px; width: 100%; max-width: 540px; }
    .btn { flex: 1; padding: 14px; border-radius: 10px; font-weight: 700; font-size: 14px; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; text-decoration: none; }
    .btn-download { background: #111827; color: #FFFFFF; border: 1px solid #000000; }
    .btn-print { background: #FFFFFF; color: #111827; border: 1px solid #D1D5DB; }
    .card { background: #FFFFFF; border: 2px solid #000000; border-radius: 12px; padding: 24px; width: 100%; box-shadow: 0 10px 25px rgba(0,0,0,0.08); }
    .tax-header { text-align: center; border-bottom: 2px solid #000000; padding-bottom: 12px; margin-bottom: 16px; }
    .tax-title { font-size: 12px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; color: #000000; margin-bottom: 4px; }
    .title { font-size: 22px; font-weight: 900; color: #000000; margin: 0 0 4px 0; }
    .info-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; border: 1px solid #000000; }
    .info-table td { padding: 8px 10px; font-size: 12px; border: 1px solid #000000; }
    .total-box { border: 2px solid #000000; border-radius: 8px; padding: 14px; display: flex; justify-content: space-between; align-items: center; margin: 16px 0; background: #F9FAFB; }
    .total-num { font-size: 22px; font-weight: 900; color: #000000; }
    .footer { text-align: center; font-size: 11px; color: #4B5563; border-top: 1px dashed #9CA3AF; padding-top: 12px; margin-top: 14px; }
    @media print {
      body { background: #FFF; color: #000; padding: 0; }
      .actions { display: none !important; }
      .card { border: none; box-shadow: none; padding: 0; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="actions">
      <button class="btn btn-download" onclick="downloadPdf()">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
        Download PDF Invoice
      </button>
      <button class="btn btn-print" onclick="window.print()">Print</button>
    </div>

    <div class="card" id="invoice-capture">
      <div class="tax-header">
        <div class="tax-title">RETAIL TAX INVOICE / CASH MEMO</div>
        <h1 class="title">${shopName}</h1>
        ${ownerName ? `<div style="font-size: 12px; font-weight: 700; color: #111827;">Proprietor: ${ownerName}</div>` : ""}
        <div style="font-size: 12px; color: #374151;">${shopAddress}</div>
        <div style="font-size: 12px; color: #374151;">Contact: ${shopPhone}${shopGstin ? ` | GSTIN: ${shopGstin}` : ""}</div>
      </div>

      <table class="info-table">
        <tr>
          <td><strong>Invoice #:</strong> #${orderId}</td>
          <td><strong>Date:</strong> ${dateStr}</td>
        </tr>
        <tr>
          <td><strong>Customer:</strong> ${payerName}</td>
          <td><strong>Payment Mode:</strong> ECO-WALLET (${statusStr})</td>
        </tr>
      </table>
      
      <div class="total-box">
        <span style="font-size: 14px; font-weight: 800; color: #000000;">TOTAL AMOUNT PAID</span>
        <span class="total-num">₹${Number(amount).toFixed(2)}</span>
      </div>

      <div style="display: flex; justify-content: space-between; align-items: center; margin: 14px 0; padding: 12px 14px; border: 1.5px solid #000000; background: #FFFFFF; border-radius: 8px;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent(orderId)}" style="width: 70px; height: 70px; border: 1px solid #000000; display: block;" alt="Invoice QR" crossOrigin="anonymous" />
          <div>
            <div style="font-size: 11px; font-weight: 900; color: #000000; letter-spacing: 0.5px; text-transform: uppercase;">SCAN TO RETURN / VERIFY</div>
            <div style="font-size: 10px; color: #4B5563; margin-top: 2px;">Scan this QR with the app to process return</div>
            <div style="font-size: 11px; font-weight: 800; color: #000000; margin-top: 2px;">ORDER ID: #${orderId}</div>
          </div>
        </div>
        <div style="text-align: right; font-size: 10px; color: #374151;">
          <div style="font-weight: 700; color: #000000;">DIGITALLY VERIFIED</div>
          <div style="color: #6B7280; font-size: 9px; margin-top: 2px;">ECO-WALLET POS</div>
        </div>
      </div>

      <div class="footer">
        <div style="font-weight: 700; color: #111827; margin-bottom: 2px;">Thank you for your business!</div>
        <div>Computer generated receipt • Dukaan Dost Smart Billing</div>
      </div>
    </div>
  </div>

  <script>
    function downloadPdf() {
      const element = document.getElementById('invoice-capture');
      const opt = {
        margin: [10, 10, 10, 10],
        filename: 'Invoice_${orderId}.pdf',
        image: { type: 'jpeg', quality: 1.0 },
        html2canvas: { scale: 3, useCORS: true, backgroundColor: '#FFFFFF' },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
      };
      html2pdf().set(opt).from(element).save();
    }
  </script>
</body>
</html>
`;

    res.setHeader("Content-Type", "text/html");
    res.send(htmlContent);
  } catch (error) {
    res.status(500).send("Error loading invoice: " + error.message);
  }
});

module.exports = router;
