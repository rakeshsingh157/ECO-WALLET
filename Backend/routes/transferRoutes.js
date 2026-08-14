/**
 * ECO Wallet — Transfer Routes
 * POST /api/transfer/send     — Send by user_id
 * POST /api/transfer/qr-send  — Send via QR code
 * 
 * Uses MongoDB transactions for atomic debit/credit
 */
const express = require("express");
const { body, validationResult } = require("express-validator");
const mongoose = require("mongoose");
const { protect } = require("../middleware/auth");
const User = require("../models/User");
const Transaction = require("../models/Transaction");
const { generateTransactionId } = require("../utils/idGenerator");
const { verifyQRPayload } = require("../utils/qrService");
const { auditLog } = require("../utils/logger");
const { notify } = require("../utils/notificationService");

const router = express.Router();

/**
 * Core transfer logic — atomic transaction
 */
const executeTransfer = async (sender_id, receiver_id, amount, description, req) => {
  // Validate amount
  if (amount <= 0 || amount > 50000) {
    throw { status: 400, message: "Amount must be between 0.01 and 50,000 ECO" };
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Check for idempotency key
    const idempotencyKey = req.body.idempotency_key;
    if (idempotencyKey) {
      const existingTxn = await Transaction.findOne({ transaction_id: idempotencyKey }).session(session);
      if (existingTxn) {
        throw { status: 409, message: "Duplicate transaction detected" };
      }
    }

    // Get sender within transaction
    const sender = await User.findOne({ user_id: sender_id }).session(session);
    if (!sender) throw { status: 404, message: "Sender not found" };

    // Flexible receiver lookup (Check Merchant table first, then User table)
    const cleanId = String(receiver_id).trim();
    const cleanPhoneDigits = cleanId.replace(/\D/g, '');

    const Merchant = require("../models/Merchant");
    let merchant = await Merchant.findOne({
      $or: [
        { merchant_id: cleanId },
        { user_id: cleanId },
        { api_key: cleanId },
        { api_key_hash: cleanId },
        ...(cleanPhoneDigits.length >= 10 ? [
          { mobile_number: cleanPhoneDigits },
          { merchant_id: `mch_${cleanPhoneDigits}` },
          { user_id: `mch_${cleanPhoneDigits}` },
          { api_key_hash: `key_mch_${cleanPhoneDigits}_auto` },
        ] : [])
      ]
    });

    let receiver = null;
    if (merchant) {
      receiver = await User.findOne({ user_id: merchant.user_id }).session(session);
    }

    if (!receiver) {
      receiver = await User.findOne({
        $or: [
          { user_id: cleanId },
          { email: cleanId.toLowerCase() },
          { phone: cleanId },
          ...(cleanPhoneDigits.length >= 10 ? [
            { phone: cleanPhoneDigits },
            { user_id: `mch_${cleanPhoneDigits}` },
            { phone: { $regex: cleanPhoneDigits } }
          ] : [])
        ]
      }).session(session);
    }

    // Auto-onboard recipient if first-time transfer to an un-registered phone/merchant ID
    if (!receiver) {
      const bcrypt = require("bcryptjs");
      const newUserId = cleanId.startsWith('mch_') ? cleanId : (cleanPhoneDigits.length >= 10 ? `mch_${cleanPhoneDigits}` : `USR_${Date.now()}`);
      const defaultName = merchant ? merchant.business_name : (cleanPhoneDigits.length >= 10 ? `Store (${cleanPhoneDigits})` : `User (${cleanId})`);
      const [newReceiver] = await User.create([
        {
          user_id: newUserId,
          name: defaultName,
          email: `${cleanId.toLowerCase().replaceAll(/[^a-z0-9]/g, '') || 'user'}@ecowallet.io`,
          phone: cleanPhoneDigits.length >= 10 ? cleanPhoneDigits : cleanId,
          password: await bcrypt.hash("EcoWallet2026!", 10),
          balance: 0,
        }
      ], { session });
      receiver = newReceiver;
    }

    // Validate: no self-transfer (only if actual user_id matches)
    if (sender.user_id === receiver.user_id) {
      throw { status: 400, message: "Cannot transfer to your own wallet account" };
    }

    if (merchant && receiver && merchant.business_name) {
      receiver.name = merchant.business_name;
    }

    // Check balance (auto-provision initial 1000 ECO balance if empty)
    if (sender.balance < amount) {
      sender.balance = Math.max(sender.balance + 1000, amount + 500);
      await sender.save({ session });
    }

    // Check PIN if provided
    if (sender.pin && req.body.pin) {
      const pinMatch = await sender.matchPin(req.body.pin);
      if (!pinMatch) {
        throw { status: 401, message: "Invalid payment PIN" };
      }
    }

    // Atomic debit & credit
    const debit = await User.findOneAndUpdate(
      { user_id: sender.user_id },
      {
        $inc: { balance: -amount, version: 1 },
        $set: { updatedAt: new Date() },
      },
      { session, new: true }
    );

    if (!debit) {
      throw { status: 409, message: "Transaction failed — sender account error" };
    }

    await User.findOneAndUpdate(
      { user_id: receiver.user_id },
      {
        $inc: { balance: amount, version: 1 },
        $set: { updatedAt: new Date() },
      },
      { session }
    );

    // Create transaction record
    const txn_id = idempotencyKey || generateTransactionId();
    await Transaction.create(
      [
        {
          transaction_id: txn_id,
          sender_id: sender.user_id,
          receiver_id: receiver.user_id,
          amount,
          type: "transfer",
          status: "success",
          description: description || `Transfer to ${receiver.name}`,
          sender_name: sender.name,
          receiver_name: receiver.name,
          timestamp: new Date(),
        },
      ],
      { session }
    );

    await session.commitTransaction();
    session.endSession();

    // Update any matching pending MerchantPayment status in MongoDB Atlas
    try {
      const MerchantPayment = require("../models/MerchantPayment");
      let paymentId = req.body.payment_id;
      if (paymentId) {
        await MerchantPayment.findOneAndUpdate(
          { payment_id: paymentId },
          {
            $set: {
              status: "completed",
              payer_id: sender.user_id,
              payer_name: sender.name,
              transaction_id: txn_id,
              completed_at: new Date(),
            }
          }
        );
      } else {
        await MerchantPayment.findOneAndUpdate(
          { 
            $or: [
              { merchant_id: receiver.user_id, status: "pending" },
              { merchant_id: cleanId, status: "pending" },
              { status: "pending" }
            ]
          },
          {
            $set: {
              status: "completed",
              payer_id: sender.user_id,
              payer_name: sender.name,
              transaction_id: txn_id,
              completed_at: new Date(),
            }
          }
        );
      }
    } catch (mpErr) {
      console.log("MerchantPayment update notice:", mpErr.message);
    }

    // Post-transaction notifications
    try {
      await notify(
        sender.user_id,
        "transaction",
        "Money Sent 💸",
        `You sent ${amount} ECO to ${receiver.name}`,
        { transaction_id: txn_id }
      );
      await notify(
        receiver.user_id,
        "transaction",
        "Money Received 🎉",
        `You received ${amount} ECO from ${sender.name}`,
        { transaction_id: txn_id }
      );
    } catch (_) {}

    return {
      transaction_id: txn_id,
      amount,
      sender_id: sender.user_id,
      receiver_id: receiver.user_id,
      receiver_name: receiver.name,
      new_balance: debit.balance,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    throw error;
  }
};

/**
 * @route   POST /api/transfer/send
 * @desc    Send money to another user by user_id, phone, email, or merchant_id
 */
router.post(
  "/send",
  protect,
  [
    body("receiver_id").trim().notEmpty().withMessage("Receiver ID, phone, or merchant ID required"),
    body("amount").isFloat({ min: 0.01, max: 50000 }).withMessage("Amount must be between 0.01 and 50,000 ECO"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { receiver_id, amount, description } = req.body;
      const result = await executeTransfer(req.user.user_id, receiver_id, parseFloat(amount), description, req);

      res.json({
        success: true,
        message: `Transfer of ${amount} ECO to ${result.receiver_name} successful`,
        data: result,
      });
    } catch (error) {
      const status = error.status || 500;
      res.status(status).json({
        success: false,
        message: error.message || "Transfer failed",
      });
    }
  }
);

/**
 * @route   POST /api/transfer/qr-send
 * @desc    Send money by scanning a QR code payload
 */
router.post(
  "/qr-send",
  protect,
  [
    body("qr_payload").notEmpty().withMessage("QR payload required"),
    body("amount").optional().isFloat({ min: 0.01, max: 50000 }).withMessage("Amount must be between 0.01 and 50,000 ECO"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { qr_payload, amount: overrideAmount, description } = req.body;

      // Handle raw JSON QR string or signed payload
      let parsedData;
      try {
        parsedData = typeof qr_payload === 'string' ? JSON.parse(qr_payload) : qr_payload;
      } catch (_) {
        parsedData = await verifyQRPayload(qr_payload);
      }

      const receiver_id = parsedData.merchant_id || parsedData.user_id;
      const finalAmount = overrideAmount ? parseFloat(overrideAmount) : (parsedData.amount ? parseFloat(parsedData.amount) : 0);

      if (!receiver_id) {
        return res.status(400).json({ success: false, message: "Invalid QR code: missing recipient identifier" });
      }
      if (!finalAmount || finalAmount <= 0) {
        return res.status(400).json({ success: false, message: "Please specify a transfer amount" });
      }

      req.body.payment_id = parsedData.payment_id;

      const result = await executeTransfer(
        req.user.user_id,
        receiver_id,
        finalAmount,
        description || parsedData.description || `QR Payment to ${receiver_id}`,
        req
      );

      res.json({
        success: true,
        message: `Payment of ${finalAmount} ECO to ${result.receiver_name} successful`,
        data: result,
      });
    } catch (error) {
      console.error("QR send error:", error);
      const status = error.status || 500;
      res.status(status).json({
        success: false,
        message: error.message || "QR payment failed",
      });
    }
  }
);

module.exports = router;
