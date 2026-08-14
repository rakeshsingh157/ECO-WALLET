const express = require("express");
const { body, validationResult } = require("express-validator");
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const Transaction = require("../models/Transaction");
const { protect, generateTokens } = require("../middleware/auth");
const { generateUserId } = require("../utils/idGenerator");
const { auditLog } = require("../utils/logger");
const { notify } = require("../utils/notificationService");

const router = express.Router();

router.post(
  "/register",
  [
    body("name").trim().isLength({ min: 2, max: 100 }).withMessage("Name must be 2-100 characters"),
    body("email").isEmail().normalizeEmail().withMessage("Valid email required"),
    body("password").isLength({ min: 8 }).withMessage("Password must be at least 8 characters"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { name, email, password, phone } = req.body;

      const exists = await User.findOne({ email });
      if (exists) {
        return res.status(400).json({
          success: false,
          message: "User with this email already exists",
        });
      }

      let user_id;
      let idExists = true;
      while (idExists) {
        user_id = generateUserId();
        idExists = await User.findOne({ user_id });
      }

      const user = await User.create({
        user_id,
        name,
        email,
        phone: phone || null,
        password,
        balance: 0,
        role: "user",
        referred_by: req.body.referral_code || null,
      });

      const tokens = generateTokens(user.user_id, user.role);

      await auditLog("USER_REGISTER", user.user_id, `New user registered: ${email}`, {}, req.ip);
      await notify(user.user_id, "system", "Welcome to ECO Wallet", `Your wallet ID is ${user.user_id}. Start earning ECO coins!`);

      res.status(201).json({
        success: true,
        message: "Account created successfully",
        data: {
          user: user.toPublic(),
          ...tokens,
        },
      });
    } catch (error) {
      console.error("Register error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);

router.post("/login", async (req, res) => {
  try {
    const rawIdentifier = (req.body.email || req.body.phone || req.body.user_id || req.body.identifier || "").trim();
    const password = req.body.password || req.body.pin || req.body.security_pin;

    if (!rawIdentifier) {
      return res.status(400).json({ success: false, message: "Email or Mobile Number is required" });
    }
    if (!password) {
      return res.status(400).json({ success: false, message: "Password or PIN is required" });
    }

    const cleanPhoneDigits = rawIdentifier.replace(/\D/g, "");
    const isEmail = rawIdentifier.includes("@");

    const query = {
      $or: [
        ...(isEmail ? [{ email: rawIdentifier.toLowerCase() }] : []),
        { user_id: rawIdentifier },
        { phone: rawIdentifier },
        ...(cleanPhoneDigits.length >= 10
          ? [
              { phone: cleanPhoneDigits },
              { user_id: `mch_${cleanPhoneDigits}` },
              { email: `${cleanPhoneDigits}@dukaandost.io` },
            ]
          : []),
      ],
    };

    let user = await User.findOne(query);

    if (!user) {
      const Merchant = require("../models/Merchant");
      const merchant = await Merchant.findOne({
        $or: [
          { merchant_id: rawIdentifier },
          ...(cleanPhoneDigits.length >= 10 ? [{ mobile_number: cleanPhoneDigits }] : []),
        ],
      });

      if (merchant) {
        user = await User.findOne({ user_id: merchant.user_id });
      }
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "No account found with these credentials. Please check your number or email.",
      });
    }

    let isMatch = false;

    if (user.password) {
      try {
        isMatch = await bcrypt.compare(password, user.password);
      } catch (_) {}
      if (!isMatch && user.password === password) {
        isMatch = true;
      }
    }

    if (!isMatch && user.pin) {
      try {
        isMatch = await bcrypt.compare(password, user.pin);
      } catch (_) {}
      if (!isMatch && user.pin === password) {
        isMatch = true;
      }
    }

    if (!isMatch) {
      await auditLog("LOGIN_FAILED", rawIdentifier, `Failed login attempt`, {}, req.ip);
      return res.status(401).json({
        success: false,
        message: "Incorrect password or PIN",
      });
    }

    const tokens = generateTokens(user.user_id, user.role);

    await auditLog("USER_LOGIN", user.user_id, `User logged in`, {}, req.ip);

    res.json({
      success: true,
      message: "Login successful",
      data: {
        user: user.toPublic(),
        ...tokens,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

router.post("/refresh", async (req, res) => {
  try {
    const tokenToVerify = req.body.refreshToken || req.body.backupRefreshToken || req.body.token;
    if (!tokenToVerify) {
      return res.status(400).json({ success: false, message: "Refresh token required" });
    }

    const jwt = require("jsonwebtoken");
    const decoded = jwt.verify(tokenToVerify, process.env.JWT_SECRET);

    if (decoded.type !== "refresh" && decoded.type !== "backup_refresh") {
      return res.status(401).json({ success: false, message: "Invalid token type" });
    }

    const user = await User.findOne({ user_id: decoded.user_id });
    if (!user) {
      return res.status(401).json({ success: false, message: "User not found" });
    }

    const tokens = generateTokens(user.user_id, user.role);
    res.json({ success: true, data: tokens });
  } catch (error) {
    res.status(401).json({ success: false, message: "Invalid refresh token" });
  }
});

router.post(
  "/set-pin",
  protect,
  [
    body("pin").matches(/^\d{6}$/).withMessage("PIN must be exactly 6 digits"),
    body("current_pin").optional().matches(/^\d{6}$/).withMessage("Current PIN must be exactly 6 digits")
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const user = await User.findOne({ user_id: req.user.user_id });
      if (!user) return res.status(404).json({ success: false, message: "User not found" });

      if (user.pin) {
        if (!req.body.current_pin) {
          return res.status(400).json({ success: false, message: "Current PIN is required to change to a new PIN" });
        }
        const isMatch = await user.matchPin(req.body.current_pin);
        if (!isMatch) {
          return res.status(401).json({ success: false, message: "Incorrect current PIN" });
        }
      }

      const salt = await bcrypt.genSalt(12);
      const pinHash = await bcrypt.hash(req.body.pin, salt);

      user.pin = pinHash;
      await user.save();

      await auditLog("PIN_SET", req.user.user_id, "Payment PIN updated", {}, req.ip);

      res.json({ success: true, message: "Payment PIN set successfully" });
    } catch (error) {
      console.error("Set PIN error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);

router.get("/me", protect, async (req, res) => {
  try {
    const user = await User.findOne({ user_id: req.user.user_id }).select("-password");
    const hasPin = !!user.pin;
    const publicData = user.toPublic();
    res.json({
      success: true,
      data: {
        ...publicData,
        has_pin: hasPin,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

router.post(
  "/remove-pin",
  protect,
  async (req, res) => {
    try {
      const user = await User.findOne({ user_id: req.user.user_id });
      if (!user) return res.status(404).json({ success: false, message: "User not found" });

      if (user.pin) {
        if (!req.body.current_pin) {
          return res.status(400).json({ success: false, message: "Current PIN is required to turn off PIN" });
        }
        const isMatch = await user.matchPin(req.body.current_pin);
        if (!isMatch) {
          return res.status(401).json({ success: false, message: "Incorrect PIN" });
        }
      }

      user.pin = null;
      await user.save();

      await auditLog("PIN_REMOVED", req.user.user_id, "Payment PIN removed", {}, req.ip);

      res.json({ success: true, message: "Payment PIN removed successfully" });
    } catch (error) {
      console.error("Remove PIN error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);

router.put(
  "/profile",
  protect,
  [
    body("name").optional({ checkFalsy: true }).trim().isLength({ min: 2, max: 100 }).withMessage("Name must be 2-100 characters"),
    body("phone").optional({ checkFalsy: true }).trim().isLength({ min: 10, max: 15 }).withMessage("Valid phone required"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const updates = {};
      if (req.body.name) updates.name = req.body.name;
      if (req.body.phone !== undefined) updates.phone = req.body.phone;

      const user = await User.findOneAndUpdate(
        { user_id: req.user.user_id },
        { $set: updates },
        { new: true }
      ).select("-password -pin");

      if (!user) {
        return res.status(404).json({ success: false, message: "User not found" });
      }

      res.json({ success: true, message: "Profile updated successfully", data: user.toPublic() });
    } catch (error) {
      console.error("Update profile error:", error);
      res.status(500).json({ success: false, message: "Server error" });
    }
  }
);

router.get("/profile", protect, async (req, res) => {
  try {
    const user = await User.findOne({ user_id: req.user.user_id }).select("-password");

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const hasPin = !!user.pin;
    const userId = req.user.user_id;

    const stats = await Transaction.aggregate([
      {
        $match: {
          $or: [
            { sender_id: userId },
            { receiver_id: userId }
          ]
        }
      },
      {
        $group: {
          _id: null,
          total_earned: {
            $sum: {
              $cond: [
                { $and: [{ $eq: ["$receiver_id", userId] }, { $eq: ["$type", "reward"] }] },
                "$amount",
                0
              ]
            }
          },
          total_sent: {
            $sum: {
              $cond: [
                { $and: [{ $eq: ["$sender_id", userId] }, { $eq: ["$type", "transfer"] }] },
                "$amount",
                0
              ]
            }
          },
          total_received: {
            $sum: {
              $cond: [
                { $and: [{ $eq: ["$receiver_id", userId] }, { $eq: ["$type", "transfer"] }] },
                "$amount",
                0
              ]
            }
          }
        }
      }
    ]);

    const userStats = stats.length > 0 ? stats[0] : { total_earned: 0, total_sent: 0, total_received: 0 };

    res.json({
      success: true,
      data: {
        ...user.toPublic(),
        has_pin: hasPin,
        stats: {
          total_earned: userStats.total_earned,
          total_sent: userStats.total_sent,
          total_received: userStats.total_received,
        }
      },
    });
  } catch (error) {
    console.error("Profile fetch error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
