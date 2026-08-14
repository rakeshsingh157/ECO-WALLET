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

// ═══════════════════════════════════════════════════════════
// BILLING SOFTWARE ENDPOINTS (API Key auth)
// ═══════════════════════════════════════════════════════════

/**
 * @route   POST /api/merchant/create-payment
 * @desc    Billing software creates a new payment request
 * @auth    X-API-Key header
 * @body    { order_id, amount, description? }
 * @returns { payment_id, qr_data, status, expires_at }
 */
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

      // 3. Begin atomic transaction
      const session = await mongoose.startSession();
      session.startTransaction();

      try {
        const customer = await User.findOne({ user_id: customer_id }).session(session);
        const merchantUser = await User.findOne({ user_id: merchant.user_id }).session(session);

        if (!customer) throw { status: 404, message: "Customer account not found" };
        if (!merchantUser) throw { status: 404, message: "Merchant account not found" };

        // Check balance
        if (customer.balance < payment.amount) {
          throw { status: 400, message: "Insufficient balance" };
        }

        // Verify PIN if set
        if (customer.pin && req.body.pin) {
          const pinMatch = await customer.matchPin(req.body.pin);
          if (!pinMatch) throw { status: 401, message: "Invalid payment PIN" };
        } else if (customer.pin && !req.body.pin) {
          throw { status: 400, message: "Payment PIN required" };
        }

        // Atomic debit customer (with optimistic concurrency)
        const debit = await User.findOneAndUpdate(
          { user_id: customer_id, version: customer.version },
          {
            $inc: { balance: -payment.amount, version: 1 },
            $set: { updatedAt: new Date() },
          },
          { session, new: true }
        );

        if (!debit) {
          throw { status: 409, message: "Transaction conflict — please retry" };
        }

        // Credit merchant
        await User.findOneAndUpdate(
          { user_id: merchant.user_id },
          {
            $inc: { balance: payment.amount, version: 1 },
            $set: { updatedAt: new Date() },
          },
          { session }
        );

        // Create Transaction record
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

        // Update MerchantPayment
        await MerchantPayment.findOneAndUpdate(
          { payment_id, status: "pending" },
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

        // Update merchant stats
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
          "Payment Successful ✅",
          `You paid ${payment.amount} ECO to ${merchant.business_name}`,
          { transaction_id: txn_id, payment_id }
        );
        await notify(
          merchant.user_id,
          "transaction",
          "Payment Received 🎉",
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
      if (status === 500) console.error("Merchant payment error:", error);
      res.status(status).json({ success: false, message });
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
    const payment = await MerchantPayment.findOne({
      $or: [{ payment_id: bill_id }, { order_id: bill_id }]
    }).lean();

    const amount = payment ? payment.amount : 220;
    const orderId = payment ? payment.order_id : bill_id;
    const payerName = payment ? (payment.payer_name || "Counter Customer") : "Valued Customer";
    const dateStr = payment && payment.completed_at ? new Date(payment.completed_at).toLocaleString() : new Date().toLocaleString();
    const statusStr = payment ? payment.status.toUpperCase() : "COMPLETED";

    const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice - ${orderId}</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background: #0F0F23; color: #FFFFFF; margin: 0; padding: 20px; display: flex; justify-content: center; }
    .card { background: #16213E; border: 1px solid rgba(255,255,255,0.15); border-radius: 20px; padding: 24px; max-width: 400px; width: 100%; box-shadow: 0 20px 40px rgba(0,0,0,0.5); }
    .header { text-align: center; border-bottom: 1px border rgba(255,255,255,0.1); padding-bottom: 16px; margin-bottom: 20px; }
    .badge { background: #4ADE80; color: #000; font-size: 12px; font-weight: 700; padding: 4px 12px; border-radius: 12px; display: inline-block; margin-top: 8px; }
    .title { font-size: 20px; font-weight: 800; color: #FFAD85; margin: 0; }
    .row { display: flex; justify-content: space-between; margin-bottom: 12px; font-size: 14px; color: #B0B8C8; }
    .val { font-weight: 700; color: #FFFFFF; }
    .total-box { background: rgba(255,173,133,0.1); border-radius: 12px; padding: 16px; text-align: center; margin: 20px 0; }
    .total-num { font-size: 32px; font-weight: 800; color: #FFAD85; }
    .btn { display: block; width: 100%; padding: 14px; background: linear-gradient(135deg, #FFAD85, #E8446D); color: #FFF; text-align: center; text-decoration: none; border-radius: 14px; font-weight: 700; border: none; cursor: pointer; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="title">Sharma Kirana Store</div>
      <div style="font-size: 12px; color: #888;">Dukaan Dost Official Invoice</div>
      <div class="badge">${statusStr}</div>
    </div>
    <div class="row"><span>Invoice ID:</span><span class="val">${orderId}</span></div>
    <div class="row"><span>Date & Time:</span><span class="val">${dateStr}</span></div>
    <div class="row"><span>Customer:</span><span class="val">${payerName}</span></div>
    
    <div class="total-box">
      <div style="font-size: 12px; color: #888;">TOTAL AMOUNT</div>
      <div class="total-num">₹${amount}</div>
    </div>

    <button class="btn" onclick="window.print()">Download / Print Invoice</button>
  </div>
  <script>
    // Auto trigger print/save on mobile scan
    setTimeout(() => {
      window.print();
    }, 800);
  </script>
</body>
</html>
    `;

    res.setHeader("Content-Type", "text/html");
    res.send(htmlContent);
  } catch (error) {
    res.status(500).send("Error loading invoice");
  }
});

module.exports = router;
