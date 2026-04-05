/**
 * ECO Wallet — Wallet Routes
 * GET  /api/wallet/balance
 * GET  /api/wallet/qr
 * GET  /api/wallet/user/:user_id — lookup user for transfer
 */
const express = require("express");
const { protect } = require("../middleware/auth");
const User = require("../models/User");
const { generateQRDataURL } = require("../utils/qrService");

const router = express.Router();

/**
 * @route   GET /api/wallet/balance
 * @desc    Get current user's wallet balance
 */
router.get("/balance", protect, async (req, res) => {
  try {
    const user = await User.findOne({ user_id: req.user.user_id }).select("balance user_id name");
    res.json({
      success: true,
      data: {
        user_id: user.user_id,
        name: user.name,
        balance: user.balance,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/wallet/qr
 * @desc    Get QR code for receiving payments
 */
router.get("/qr", protect, async (req, res) => {
  try {
    const amount = req.query.amount ? parseFloat(req.query.amount) : undefined;
    const { dataUrl, payload } = await generateQRDataURL(req.user.user_id, amount);
    res.json({
      success: true,
      data: {
        user_id: req.user.user_id,
        qr_image: dataUrl,
        payload,
      },
    });
  } catch (error) {
    console.error("QR generation error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/wallet/user/:user_id
 * @desc    Lookup a user by ID (for transfer previews)
 */
router.get("/user/:user_id", protect, async (req, res) => {
  try {
    const user = await User.findOne({ user_id: req.params.user_id }).select("user_id name");
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }
    res.json({
      success: true,
      data: {
        user_id: user.user_id,
        name: user.name,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
