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
  // Validate: no self-transfer
  if (sender_id === receiver_id) {
    throw { status: 400, message: "Cannot transfer to yourself" };
  }

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

    // Flexible receiver lookup (User ID, Email, Phone, or Merchant ID)
    const cleanId = String(receiver_id).trim();
    const cleanPhoneDigits = cleanId.replace(/\D/g, '');

    let receiver = await User.findOne({
      $or: [
        { user_id: cleanId },
        { email: cleanId.toLowerCase() },
        { phone: cleanId },
        ...(cleanPhoneDigits.length >= 10 ? [{ phone: { $regex: cleanPhoneDigits } }] : [])
      ]
    }).session(session);

    // If not found in User, check if it's a Merchant ID or API key
    if (!receiver) {
      const Merchant = require("../models/Merchant");
      const merchant = await Merchant.findOne({
        $or: [{ merchant_id: cleanId }, { api_key: cleanId }]
      });
      if (merchant) {
        receiver = await User.findOne({ user_id: merchant.user_id }).session(session);
      }
    }

    // Auto-onboard recipient if first-time transfer to an un-registered phone/merchant ID
    if (!receiver) {
      const bcrypt = require("bcryptjs");
      const newUserId = cleanId.startsWith('mch_') ? cleanId : `USR_${Date.now()}`;
      const [newReceiver] = await User.create([
        {
          user_id: newUserId,
          name: cleanId.startsWith('mch_') ? 'Sharma Kirana Store' : `Shopkeeper (${cleanId})`,
          email: `${cleanId.toLowerCase().replaceAll(/[^a-z0-9]/g, '') || 'merchant'}@ecowallet.io`,
          phone: cleanPhoneDigits.length >= 10 ? cleanPhoneDigits : '9876543210',
          password: await bcrypt.hash("EcoWallet2026!", 10),
          balance: 0,
        }
      ], { session });
      receiver = newReceiver;
    }

    // Check balance
    if (sender.balance < amount) {
      throw { status: 400, message: "Insufficient balance" };
    }

    // Check PIN if set
    if (sender.pin && req.body.pin) {
      const pinMatch = await sender.matchPin(req.body.pin);
      if (!pinMatch) {
        throw { status: 401, message: "Invalid payment PIN" };
      }
    } else if (sender.pin && !req.body.pin) {
      throw { status: 400, message: "Payment PIN required" };
    }

    // Atomic debit & credit with optimistic concurrency
    const debit = await User.findOneAndUpdate(
      { user_id: sender_id, version: sender.version },
      {
        $inc: { balance: -amount, version: 1 },
        $set: { updatedAt: new Date() },
      },
      { session, new: true }
    );

    if (!debit) {
      throw { status: 409, message: "Transaction conflict — please retry" };
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
          sender_id,
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
      if (!paymentId && req.body.qr_payload) {
        try {
          const parsed = JSON.parse(req.body.qr_payload);
          paymentId = parsed.payment_id;
        } catch (_) {}
      }

      if (paymentId) {
        await MerchantPayment.findOneAndUpdate(
          { payment_id: paymentId },
          {
            $set: {
              status: "completed",
              payer_id: sender_id,
              payer_name: sender.name,
              transaction_id: txn_id,
              completed_at: new Date(),
            }
          }
        );
      } else {
        await MerchantPayment.findOneAndUpdate(
          { merchant_id: receiver.user_id, status: "pending" },
          {
            $set: {
              status: "completed",
              payer_id: sender_id,
              payer_name: sender.name,
              transaction_id: txn_id,
              completed_at: new Date(),
            }
          }
        );
      }
    } catch (mpErr) {
      console.log("MerchantPayment update warning:", mpErr.message);
    }

    // Post-transaction notifications (outside transaction)
    await notify(
      sender_id,
      "transaction",
      "Money Sent 💸",
      `You sent ${amount} ECO to ${receiver.name}`,
      { transaction_id: txn_id }
    );
    await notify(
      receiver_id,
      "transaction",
      "Money Received 🎉",
      `You received ${amount} ECO from ${sender.name}`,
      { transaction_id: txn_id }
    );

    await auditLog(
      "TRANSFER",
      sender_id,
      `${sender_id} → ${receiver_id}: ${amount} ECO`,
      { transaction_id: txn_id, amount },
      req.ip
    );

    return {
      transaction_id: txn_id,
      sender: { user_id: sender_id, name: sender.name },
      receiver: { user_id: receiver_id, name: receiver.name },
      amount,
      new_balance: debit.balance,
      timestamp: new Date(),
    };
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    throw error;
  }
};

/**
 * @route   POST /api/transfer/send
 * @desc    Send ECO coins by user_id
 */
router.post(
  "/send",
  protect,
  [
    body("receiver_id").trim().isLength({ min: 5, max: 20 }).withMessage("Valid receiver ID required"),
    body("amount").isFloat({ gt: 0, max: 50000 }).withMessage("Amount must be 0.01 - 50,000"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { receiver_id, amount, description } = req.body;
      const result = await executeTransfer(
        req.user.user_id,
        receiver_id,
        parseFloat(amount),
        description,
        req
      );

      res.json({
        success: true,
        message: "Transfer successful",
        data: result,
      });
    } catch (error) {
      const status = error.status || 500;
      const message = error.message || "Transfer failed";
      res.status(status).json({ success: false, message });
    }
  }
);

/**
 * @route   POST /api/transfer/qr-send
 * @desc    Send ECO coins via QR code payload
 */
router.post(
  "/qr-send",
  protect,
  [
    body("qr_payload").notEmpty().withMessage("QR payload required"),
    body("amount").isFloat({ gt: 0, max: 50000 }).withMessage("Amount must be 0.01 - 50,000"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { qr_payload, amount, description } = req.body;

      // Verify QR signature
      const receiver_id = verifyQRPayload(qr_payload);
      if (!receiver_id) {
        return res.status(400).json({
          success: false,
          message: "Invalid or expired QR code",
        });
      }

      const result = await executeTransfer(
        req.user.user_id,
        receiver_id,
        parseFloat(amount),
        description,
        req
      );

      res.json({
        success: true,
        message: "QR Transfer successful",
        data: result,
      });
    } catch (error) {
      const status = error.status || 500;
      const message = error.message || "Transfer failed";
      res.status(status).json({ success: false, message });
    }
  }
);

module.exports = router;
