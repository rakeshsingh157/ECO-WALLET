const express = require("express");
const { protect } = require("../middleware/auth");
const User = require("../models/User");
const Merchant = require("../models/Merchant");
const { generateQRDataURL } = require("../utils/qrService");

const router = express.Router();

router.get("/balance", protect, async (req, res) => {
  try {
    const user = await User.findOne({ user_id: req.user.user_id }).select("balance user_id name");
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
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
    res.status(500).json({ success: false, message: "Server error" });
  }
});

router.get("/user/:user_id", protect, async (req, res) => {
  try {
    const cleanId = String(req.params.user_id || "").trim();
    if (!cleanId) {
      return res.status(400).json({ success: false, message: "Recipient identifier required" });
    }

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
    });

    let user = null;
    if (merchant) {
      user = await User.findOne({ user_id: merchant.user_id }).select("user_id name phone email balance");
    }

    if (!user) {
      user = await User.findOne({
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
      }).select("user_id name phone email balance");
    }

    if (!user && !merchant) {
      return res.status(404).json({
        success: false,
        message: "Recipient not found. No account is registered with this ID or phone number.",
      });
    }

    let displayName = "";
    if (merchant && merchant.business_name) {
      displayName = merchant.business_name;
    } else if (merchant && merchant.owner_name) {
      displayName = merchant.owner_name;
    } else if (user && user.name) {
      displayName = user.name;
    } else {
      displayName = cleanId;
    }

    const resolvedUserId = user ? user.user_id : (merchant ? merchant.user_id : cleanId);

    res.json({
      success: true,
      data: {
        user_id: resolvedUserId,
        name: displayName,
        phone: user ? user.phone : (merchant ? merchant.mobile_number : ""),
        is_merchant: !!merchant,
        shop_name: merchant ? (merchant.business_name || merchant.shop_name) : null,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
