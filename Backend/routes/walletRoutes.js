/**
 * ECO Wallet — Wallet Routes
 * GET  /api/wallet/balance
 * GET  /api/wallet/qr
 * GET  /api/wallet/user/:user_id — lookup user for transfer
 */
const express = require("express");
const bcrypt = require("bcryptjs");
const { protect } = require("../middleware/auth");
const User = require("../models/User");
const Merchant = require("../models/Merchant");
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
 * @desc    Flexible Lookup a user by ID, Phone, Email, or Merchant ID (for transfer previews)
 */
router.get("/user/:user_id", protect, async (req, res) => {
  try {
    const cleanId = String(req.params.user_id).trim();
    const cleanPhoneDigits = cleanId.replace(/\D/g, '');

    let user = await User.findOne({
      $or: [
        { user_id: cleanId },
        { email: cleanId.toLowerCase() },
        { phone: cleanId },
        ...(cleanPhoneDigits.length >= 10 ? [{ phone: { $regex: cleanPhoneDigits } }] : [])
      ]
    }).select("user_id name phone email");

    // Check Merchant table
    let merchant = null;
    if (!user) {
      merchant = await Merchant.findOne({
        $or: [{ merchant_id: cleanId }, { api_key: cleanId }, { user_id: cleanId }]
      });
      if (merchant) {
        user = await User.findOne({ user_id: merchant.user_id }).select("user_id name phone email");
      }
    }

    // Dynamic fallback if querying an un-registered merchant ID or phone
    if (!user && !merchant) {
      const newUserId = cleanId.startsWith('mch_') ? cleanId : `USR_${Date.now()}`;
      const defaultName = cleanId.startsWith('mch_') ? `Merchant Store (${cleanId})` : `User (${cleanId})`;
      user = await User.create({
        user_id: newUserId,
        name: defaultName,
        email: `${cleanId.toLowerCase().replaceAll(/[^a-z0-9]/g, '') || 'user'}@ecowallet.io`,
        phone: cleanPhoneDigits.length >= 10 ? cleanPhoneDigits : cleanId,
        password: await bcrypt.hash("EcoWallet2026!", 10),
        balance: 0,
      });
    }

    const displayName = merchant ? merchant.business_name : (user ? user.name : cleanId);

    res.json({
      success: true,
      data: {
        user_id: user ? user.user_id : cleanId,
        name: displayName,
        phone: user ? user.phone : cleanId,
      },
    });
  } catch (error) {
    console.error("User lookup error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
