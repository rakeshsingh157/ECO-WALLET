const express = require("express");
const router = express.Router();
const User = require("../models/User");
const Merchant = require("../models/Merchant");
const { getEcoWalletConnection } = require("../config/db");

async function syncToEcoWalletDB(userData, merchantData) {
  try {
    const ecoConn = getEcoWalletConnection();
    if (!ecoConn) return;

    if (ecoConn.readyState !== 1) {
      await ecoConn.asPromise().catch(() => null);
    }

    if (ecoConn.readyState === 1) {
      const EcoUser = ecoConn.models.User || ecoConn.model("User", User.schema);
      const EcoMerchant = ecoConn.models.Merchant || ecoConn.model("Merchant", Merchant.schema);

      await Promise.allSettled([
        EcoUser.findOneAndUpdate(
          { $or: [{ user_id: userData.user_id }, { phone: userData.phone }] },
          { $set: userData },
          { upsert: true, new: true, maxTimeMS: 5000 }
        ),
        EcoMerchant.findOneAndUpdate(
          { $or: [{ merchant_id: merchantData.merchant_id }, { mobile_number: merchantData.mobile_number }] },
          { $set: merchantData },
          { upsert: true, new: true, maxTimeMS: 5000 }
        ),
      ]);

      console.log(`[INFO] Synchronized merchant record: ${merchantData.merchant_id}`);
    }
  } catch (err) {
    console.error("[ERROR] Merchant sync error:", err.message);
  }
}

router.post("/signup", async (req, res) => {
  try {
    const { mobile_number, shop_name, owner_name, security_pin } = req.body;

    if (!mobile_number || mobile_number.trim().length < 10) {
      return res.status(400).json({ success: false, message: "A valid 10-digit mobile number is required" });
    }
    if (!shop_name || shop_name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Shop name is required" });
    }
    if (!owner_name || owner_name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Owner name is required" });
    }
    if (!security_pin || security_pin.trim().length !== 4) {
      return res.status(400).json({ success: false, message: "A 4-digit Security PIN is required" });
    }

    const phone = mobile_number.trim();
    const mchId = `mch_${phone}`;
    const bName = shop_name.trim();
    const oName = owner_name.trim();
    const pin = security_pin.trim();

    const existingUser = await User.findOne({ $or: [{ phone }, { user_id: mchId }] });
    const existingMerchant = await Merchant.findOne({ $or: [{ mobile_number: phone }, { merchant_id: mchId }] });

    if (existingUser || existingMerchant) {
      return res.status(409).json({
        success: false,
        message: "An account with this mobile number already exists. Please switch to Sign In.",
      });
    }

    const userData = {
      user_id: mchId,
      name: oName,
      email: `${phone}@dukaandost.io`,
      phone: phone,
      password: pin,
      pin: pin,
      balance: 1000,
      role: "user",
    };
    const user = await User.create(userData);

    const autoApiKey = `key_mch_${phone}_auto`;
    const autoWebhookSecret = `whsec_auto_${phone}`;
    const merchantData = {
      merchant_id: mchId,
      user_id: user.user_id,
      business_name: bName,
      owner_name: oName,
      mobile_number: phone,
      webhook_url: "http://localhost:5001/api/webhook",
      webhook_secret: autoWebhookSecret,
      api_key_hash: autoApiKey,
      is_active: true,
    };
    const merchant = await Merchant.create(merchantData);

    console.log(`[INFO] Registered new merchant: ${mchId}`);

    await syncToEcoWalletDB(userData, merchantData);

    res.status(201).json({
      success: true,
      message: `Welcome, ${oName}. Store ${bName} registered successfully.`,
      merchant: {
        merchant_id: merchant.merchant_id,
        user_id: merchant.user_id,
        business_name: merchant.business_name,
        owner_name: merchant.owner_name,
        mobile_number: merchant.mobile_number,
        api_key: autoApiKey,
        webhook_secret: autoWebhookSecret,
      },
    });
  } catch (error) {
    console.error("[ERROR] Merchant registration failed:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { mobile_number, security_pin } = req.body;

    if (!mobile_number || mobile_number.trim().length < 10) {
      return res.status(400).json({ success: false, message: "A valid 10-digit mobile number is required" });
    }
    if (!security_pin || security_pin.trim().length !== 4) {
      return res.status(400).json({ success: false, message: "A 4-digit Security PIN is required" });
    }

    const phone = mobile_number.trim();
    const pin = security_pin.trim();
    const mchId = `mch_${phone}`;

    let user = await User.findOne({ $or: [{ phone }, { user_id: mchId }] });
    let merchant = await Merchant.findOne({ $or: [{ mobile_number: phone }, { merchant_id: mchId }] });

    if (!user && !merchant) {
      return res.status(404).json({
        success: false,
        message: "No merchant account found for this mobile number. Please Sign Up first.",
      });
    }

    if (user && user.pin) {
      const isMatch = await user.matchPin(pin);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: "Incorrect Security PIN. Access Denied.",
        });
      }
    }

    if (!user && merchant) {
      user = await User.create({
        user_id: merchant.user_id || mchId,
        name: merchant.owner_name || "Shopkeeper",
        email: `${phone}@dukaandost.io`,
        phone: phone,
        password: pin,
        pin: pin,
        balance: 1000,
        role: "user",
      });
    } else if (user && !user.pin) {
      user.pin = pin;
      user.password = pin;
      await user.save();
    }

    const shopName = merchant ? merchant.business_name : "My Dukaan";
    const ownerName = merchant ? merchant.owner_name : (user ? user.name : "Shopkeeper");
    const autoApiKey = merchant ? (merchant.api_key_hash || `key_mch_${phone}_auto`) : `key_mch_${phone}_auto`;
    const autoWebhookSecret = merchant ? (merchant.webhook_secret || `whsec_auto_${phone}`) : `whsec_auto_${phone}`;

    await syncToEcoWalletDB(
      {
        user_id: user.user_id,
        name: ownerName,
        email: `${phone}@dukaandost.io`,
        phone: phone,
        password: pin,
        pin: pin,
        balance: 1000,
        role: "user",
      },
      {
        merchant_id: merchant ? merchant.merchant_id : mchId,
        user_id: user.user_id,
        business_name: shopName,
        owner_name: ownerName,
        mobile_number: phone,
        webhook_url: "http://localhost:5001/api/webhook",
        webhook_secret: autoWebhookSecret,
        api_key_hash: autoApiKey,
        is_active: true,
      }
    );

    console.log(`[INFO] Merchant authenticated: ${mchId}`);

    res.json({
      success: true,
      message: `Welcome back, ${ownerName}`,
      merchant: {
        merchant_id: merchant ? merchant.merchant_id : mchId,
        user_id: user ? user.user_id : mchId,
        business_name: shopName,
        owner_name: ownerName,
        mobile_number: phone,
        api_key: autoApiKey,
        webhook_secret: autoWebhookSecret,
      },
    });
  } catch (error) {
    console.error("[ERROR] Authentication failure:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post("/onboard", async (req, res) => {
  try {
    const { mobile_number, shop_name, owner_name, security_pin, api_key, merchant_id } = req.body;
    const phone = mobile_number || "9876543210";
    const mchId = merchant_id || `mch_${phone}`;
    const bName = shop_name || "Store";
    const oName = owner_name || "Shopkeeper";

    let user = await User.findOne({ $or: [{ phone }, { user_id: mchId }] });
    if (!user) {
      user = await User.create({
        user_id: mchId,
        name: oName,
        email: `${phone}@dukaandost.io`,
        phone: phone,
        password: security_pin || "1234",
        pin: security_pin || "1234",
        balance: 1000,
        role: "user",
      });
    } else {
      user.name = oName;
      if (security_pin) {
        user.password = security_pin;
        user.pin = security_pin;
      }
      await user.save();
    }

    let merchant = await Merchant.findOne({ merchant_id: mchId });
    if (!merchant) {
      merchant = await Merchant.create({
        merchant_id: mchId,
        user_id: user.user_id,
        business_name: bName,
        owner_name: oName,
        mobile_number: phone,
        webhook_url: "http://localhost:5001/api/webhook",
        webhook_secret: `whsec_${phone}`,
        api_key_hash: api_key || `key_${phone}`,
        is_active: true,
      });
    } else {
      merchant.business_name = bName;
      merchant.owner_name = oName;
      merchant.mobile_number = phone;
      await merchant.save();
    }

    await syncToEcoWalletDB(
      {
        user_id: user.user_id,
        name: oName,
        email: `${phone}@dukaandost.io`,
        phone: phone,
        password: security_pin || "1234",
        pin: security_pin || "1234",
        balance: 1000,
        role: "user",
      },
      {
        merchant_id: merchant.merchant_id,
        user_id: user.user_id,
        business_name: bName,
        owner_name: oName,
        mobile_number: phone,
        webhook_url: "http://localhost:5001/api/webhook",
        webhook_secret: `whsec_${phone}`,
        api_key_hash: api_key || `key_${phone}`,
        is_active: true,
      }
    );

    res.json({
      success: true,
      message: "Merchant account configured successfully",
      merchant: {
        merchant_id: merchant.merchant_id,
        user_id: merchant.user_id,
        business_name: merchant.business_name,
        owner_name: merchant.owner_name,
        mobile_number: merchant.mobile_number,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
