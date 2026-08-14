const express = require("express");
const { body, validationResult } = require("express-validator");
const mongoose = require("mongoose");
const { protect } = require("../middleware/auth");
const User = require("../models/User");
const Merchant = require("../models/Merchant");
const MerchantPayment = require("../models/MerchantPayment");
const Transaction = require("../models/Transaction");
const { generateTransactionId } = require("../utils/idGenerator");
const { verifyQRPayload } = require("../utils/qrService");
const { auditLog } = require("../utils/logger");
const { notify } = require("../utils/notificationService");

const router = express.Router();

const executeTransfer = async (sender_id, receiver_id, amount, description, req) => {
  if (!amount || isNaN(amount) || amount <= 0 || amount > 50000) {
    throw { status: 400, message: "Amount must be between 0.01 and 50,000 ECO" };
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const idempotencyKey = req.body.idempotency_key;
    if (idempotencyKey) {
      const existingTxn = await Transaction.findOne({ transaction_id: idempotencyKey }).session(session);
      if (existingTxn) {
        throw { status: 409, message: "Duplicate transaction detected" };
      }
    }

    const sender = await User.findOne({ user_id: sender_id }).session(session);
    if (!sender) {
      throw { status: 404, message: "Sender account not found" };
    }

    const cleanId = String(receiver_id || "").trim();
    const cleanPhoneDigits = cleanId.replace(/\D/g, "");

    let merchant = await Merchant.findOne({
      $or: [
        { merchant_id: cleanId },
        { user_id: cleanId },
        { api_key: cleanId },
        { api_key_hash: cleanId },
        ...(cleanPhoneDigits.length >= 10
          ? [
              { mobile_number: cleanPhoneDigits },
              { merchant_id: `mch_${cleanPhoneDigits}` },
              { user_id: `mch_${cleanPhoneDigits}` },
              { api_key_hash: `key_mch_${cleanPhoneDigits}_auto` },
            ]
          : []),
      ],
    }).session(session);

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
          ...(cleanPhoneDigits.length >= 10
            ? [
                { phone: cleanPhoneDigits },
                { user_id: `mch_${cleanPhoneDigits}` },
              ]
            : []),
        ],
      }).session(session);
    }

    if (!receiver) {
      throw {
        status: 404,
        message: "Recipient not found. No account is registered with this ID or phone number.",
      };
    }

    if (sender.user_id === receiver.user_id) {
      throw { status: 400, message: "Cannot transfer money to your own wallet account" };
    }

    if (sender.balance < amount) {
      throw {
        status: 400,
        message: `Insufficient wallet balance. Your balance is ${sender.balance.toFixed(2)} ECO.`,
      };
    }

    if (sender.pin && req.body.pin) {
      const pinMatch = await sender.matchPin(req.body.pin);
      if (!pinMatch) {
        throw { status: 401, message: "Invalid payment PIN" };
      }
    }

    let receiverDisplayName = receiver.name;
    if (merchant && merchant.business_name) {
      receiverDisplayName = merchant.business_name;
    } else if (merchant && merchant.owner_name) {
      receiverDisplayName = merchant.owner_name;
    }

    const debit = await User.findOneAndUpdate(
      { user_id: sender.user_id, balance: { $gte: amount } },
      {
        $inc: { balance: -amount },
        $set: { updatedAt: new Date() },
      },
      { session, new: true }
    );

    if (!debit) {
      throw { status: 400, message: "Transfer aborted: insufficient balance or account locked" };
    }

    const credit = await User.findOneAndUpdate(
      { user_id: receiver.user_id },
      {
        $inc: { balance: amount },
        $set: { updatedAt: new Date() },
      },
      { session, new: true }
    );

    if (!credit) {
      throw { status: 500, message: "Transfer aborted: recipient account credit failed" };
    }

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
          description: description || `Transfer to ${receiverDisplayName}`,
          sender_name: sender.name,
          receiver_name: receiverDisplayName,
          timestamp: new Date(),
        },
      ],
      { session }
    );

    await session.commitTransaction();
    session.endSession();

    try {
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
            },
          }
        );
      }
    } catch (_) {}

    try {
      await notify(
        sender.user_id,
        "transaction",
        "Money Sent",
        `You sent ${amount} ECO to ${receiverDisplayName}`,
        { transaction_id: txn_id }
      );
      await notify(
        receiver.user_id,
        "transaction",
        "Money Received",
        `You received ${amount} ECO from ${sender.name}`,
        { transaction_id: txn_id }
      );
    } catch (_) {}

    return {
      transaction_id: txn_id,
      amount,
      sender_id: sender.user_id,
      receiver_id: receiver.user_id,
      receiver_name: receiverDisplayName,
      new_balance: debit.balance,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    throw error;
  }
};

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

      let parsedData;
      try {
        parsedData = typeof qr_payload === "string" ? JSON.parse(qr_payload) : qr_payload;
      } catch (_) {
        parsedData = await verifyQRPayload(qr_payload);
      }

      const receiver_id = parsedData.merchant_id || parsedData.user_id || parsedData.merchant;
      const finalAmount = overrideAmount ? parseFloat(overrideAmount) : (parsedData.amount ? parseFloat(parsedData.amount) : 0);

      if (!receiver_id) {
        return res.status(400).json({ success: false, message: "Invalid QR code: missing recipient identifier" });
      }
      if (!finalAmount || finalAmount <= 0) {
        return res.status(400).json({ success: false, message: "Please specify a valid transfer amount" });
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
      const status = error.status || 500;
      res.status(status).json({
        success: false,
        message: error.message || "QR payment failed",
      });
    }
  }
);

module.exports = router;
