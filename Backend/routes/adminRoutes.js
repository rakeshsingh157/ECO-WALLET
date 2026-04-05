/**
 * ECO Wallet — Admin Routes
 * POST /api/admin/mint         — Mint new ECO coins to bank
 * GET  /api/admin/bank-status  — Get central bank status
 * GET  /api/admin/logs         — Get audit logs
 * GET  /api/admin/users        — List all users
 */
const express = require("express");
const { body, validationResult } = require("express-validator");
const { protect, requireAdmin } = require("../middleware/auth");
const Bank = require("../models/Bank");
const User = require("../models/User");
const Transaction = require("../models/Transaction");
const Log = require("../models/Log");
const { generateTransactionId } = require("../utils/idGenerator");
const { auditLog } = require("../utils/logger");
const { notify } = require("../utils/notificationService");

const router = express.Router();

// All admin routes require auth + admin role
router.use(protect, requireAdmin);

/**
 * @route   POST /api/admin/mint
 * @desc    Mint new ECO coins into the central bank
 */
router.post(
  "/mint",
  [
    body("amount").isFloat({ gt: 0 }).withMessage("Amount must be positive"),
    body("reason").trim().isLength({ min: 3 }).withMessage("Reason required"),
    body("admin_secret").notEmpty().withMessage("Admin secret key required"),
    body("otp").notEmpty().withMessage("OTP required"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { amount, reason, admin_secret, otp } = req.body;

      // Verify admin secret key
      if (admin_secret !== process.env.ADMIN_SECRET_KEY) {
        await auditLog(
          "MINT_REJECTED",
          req.user.user_id,
          "Invalid admin secret key",
          { amount },
          req.ip,
          "admin"
        );
        return res.status(403).json({
          success: false,
          message: "Invalid admin secret key",
        });
      }

      // Simulated OTP verification (for demo: accept "000000" or any 6-digit)
      if (!/^\d{6}$/.test(otp)) {
        return res.status(400).json({
          success: false,
          message: "Invalid OTP format (6 digits required)",
        });
      }

      const bank = await Bank.findOne({});
      if (!bank) {
        return res.status(500).json({ success: false, message: "Bank not initialized" });
      }

      // Check daily mint limit
      const today = new Date().toISOString().split("T")[0];
      let todayMinted = bank.getTodayMinted();
      if (bank.daily_mint_date !== today) {
        todayMinted = 0;
      }

      const dailyLimit = parseFloat(process.env.DAILY_MINT_LIMIT) || 10000;
      if (todayMinted + amount > dailyLimit) {
        return res.status(400).json({
          success: false,
          message: `Daily mint limit exceeded. Remaining: ${dailyLimit - todayMinted} ECO`,
        });
      }

      // Check max supply cap
      const maxCap = parseFloat(process.env.MAX_SUPPLY_CAP) || 1000000;
      if (bank.total_minted + amount > maxCap) {
        return res.status(400).json({
          success: false,
          message: `Max supply cap would be exceeded. Cap: ${maxCap}, Current: ${bank.total_minted}`,
        });
      }

      // Mint!
      bank.total_balance += amount;
      bank.total_minted += amount;
      bank.daily_minted = todayMinted + amount;
      bank.daily_mint_date = today;
      if (bank.status === "exhausted") {
        bank.status = "active";
      }
      await bank.save();

      // Log transaction
      const txn_id = generateTransactionId();
      await Transaction.create({
        transaction_id: txn_id,
        sender_id: "ADMIN",
        receiver_id: "BANK",
        amount,
        type: "mint",
        status: "success",
        description: `Mint: ${reason}`,
        sender_name: req.user.name,
        receiver_name: "ECO Central Bank",
        timestamp: new Date(),
      });

      // Audit log
      await auditLog(
        "MINT",
        req.user.user_id,
        `Minted ${amount} ECO. Reason: ${reason}`,
        { amount, reason, transaction_id: txn_id, new_bank_balance: bank.total_balance },
        req.ip,
        "admin"
      );

      // Notify admin
      await notify(
        req.user.user_id,
        "system",
        "Mint Successful ✅",
        `${amount} ECO coins minted to central bank. Reason: ${reason}`
      );

      res.json({
        success: true,
        message: `Successfully minted ${amount} ECO coins`,
        data: {
          transaction_id: txn_id,
          amount,
          new_bank_balance: bank.total_balance,
          total_minted: bank.total_minted,
          daily_remaining: dailyLimit - (todayMinted + amount),
        },
      });
    } catch (error) {
      console.error("Mint error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);

/**
 * @route   GET /api/admin/bank-status
 * @desc    Get central bank status
 */
router.get("/bank-status", async (req, res) => {
  try {
    const bank = await Bank.findOne({}).lean();
    if (!bank) {
      return res.status(500).json({ success: false, message: "Bank not initialized" });
    }

    const userCount = await User.countDocuments({ role: "user" });
    const txnCount = await Transaction.countDocuments();

    res.json({
      success: true,
      data: {
        ...bank,
        user_count: userCount,
        transaction_count: txnCount,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/admin/logs
 * @desc    Get audit logs (paginated)
 */
router.get("/logs", async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [logs, total] = await Promise.all([
      Log.find({})
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Log.countDocuments(),
    ]);

    res.json({
      success: true,
      data: { logs, pagination: { page: parseInt(page), limit: parseInt(limit), total } },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/admin/users
 * @desc    List all users
 */
router.get("/users", async (req, res) => {
  try {
    const users = await User.find({})
      .select("-password -pin")
      .sort({ createdAt: -1 })
      .lean();

    res.json({
      success: true,
      data: users.map((u) => ({
        user_id: u.user_id,
        name: u.name,
        email: u.email,
        balance: u.balance,
        role: u.role,
        createdAt: u.createdAt,
      })),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
