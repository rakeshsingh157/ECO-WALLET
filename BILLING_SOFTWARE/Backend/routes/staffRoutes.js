const express = require("express");
const router = express.Router();
const StaffMember = require("../models/StaffMember");
const Merchant = require("../models/Merchant");
const User = require("../models/User");

router.get("/", async (req, res) => {
  try {
    const merchantId = req.merchant_id || req.headers["x-merchant-id"] || req.query.merchant_id || "mch_default";
    const query = { merchant_id: merchantId };
    const staff = await StaffMember.find(query).sort({ createdAt: -1 });
    res.json({ success: true, count: staff.length, data: staff });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.post("/", async (req, res) => {
  try {
    const { name, phone, role, pin, member_id, merchant_id } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Staff member name is required" });
    }
    if (!phone || phone.trim().length < 10) {
      return res.status(400).json({ success: false, message: "A valid 10-digit mobile number is required" });
    }

    const cleanPhone = phone.trim();
    const cleanPin = pin && pin.trim().length === 4 ? pin.trim() : "1234";
    const memberId = member_id || `m_${Date.now()}`;
    const mchId = req.merchant_id || merchant_id || req.headers["x-merchant-id"] || "mch_default";

    const existingMember = await StaffMember.findOne({ phone: cleanPhone, merchant_id: mchId });
    if (existingMember) {
      existingMember.name = name.trim();
      existingMember.role = role || "Counter Cashier";
      existingMember.pin = cleanPin;
      existingMember.active = true;
      await existingMember.save();
      return res.status(200).json({ success: true, data: existingMember, message: "Staff member details updated" });
    }

    const newMember = new StaffMember({
      member_id: memberId,
      merchant_id: mchId,
      name: name.trim(),
      phone: cleanPhone,
      role: role || "Counter Cashier",
      pin: cleanPin,
      active: true,
    });

    await newMember.save();
    res.status(201).json({ success: true, data: newMember });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { phone, pin, mobile_number, security_pin } = req.body;
    const cleanPhone = (phone || mobile_number || "").trim();
    const cleanPin = (pin || security_pin || "").trim();

    if (!cleanPhone || cleanPhone.length < 10) {
      return res.status(400).json({ success: false, message: "A valid 10-digit registered mobile number is required" });
    }
    if (!cleanPin || cleanPin.length !== 4) {
      return res.status(400).json({ success: false, message: "A 4-digit Security PIN is required" });
    }

    const staffMember = await StaffMember.findOne({ phone: cleanPhone, active: true });
    if (!staffMember) {
      return res.status(404).json({
        success: false,
        message: "No active staff member found with this mobile number. Please ask the store owner to add you first.",
      });
    }

    const isMatch = await staffMember.matchPin(cleanPin);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Incorrect PIN. Please enter the 4-digit PIN assigned by your store owner.",
      });
    }

    let merchant = await Merchant.findOne({
      $or: [
        { merchant_id: staffMember.merchant_id },
        { mobile_number: staffMember.merchant_id.replace(/^mch_/, "") },
      ],
    }).sort({ createdAt: -1 });

    const ownerPhone = merchant ? merchant.mobile_number : "9876543210";
    const shopName = merchant ? merchant.business_name : "Dukaan Dost Store";
    const ownerName = merchant ? merchant.owner_name : "Store Owner";
    const apiKey = merchant ? (merchant.api_key_hash || `key_mch_${ownerPhone}_auto`) : `key_mch_${ownerPhone}_auto`;
    const merchantId = merchant ? merchant.merchant_id : (staffMember.merchant_id || `mch_${ownerPhone}`);

    res.json({
      success: true,
      message: `Welcome back, ${staffMember.name}. Logged into ${shopName}.`,
      is_staff: true,
      staff: {
        member_id: staffMember.member_id,
        name: staffMember.name,
        role: staffMember.role,
        phone: staffMember.phone,
      },
      merchant: {
        merchant_id: merchantId,
        business_name: shopName,
        owner_name: ownerName,
        mobile_number: ownerPhone,
        api_key: apiKey,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const query = {
      merchant_id: merchantId,
      $or: [{ member_id: req.params.id }, { _id: req.params.id.match(/^[0-9a-fA-F]{24}$/) ? req.params.id : null }],
    };
    const deleted = await StaffMember.findOneAndDelete(query);
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Staff member not found" });
    }
    res.json({ success: true, message: "Staff member removed successfully" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/verify-pin", async (req, res) => {
  try {
    const { member_id, pin } = req.body;
    const merchantId = req.merchant_id || "mch_default";
    if (!member_id || !pin) {
      return res.status(400).json({ success: false, message: "Member ID and PIN are required" });
    }

    const member = await StaffMember.findOne({ merchant_id: merchantId, member_id });
    if (!member) {
      return res.status(404).json({ success: false, message: "Staff member not found" });
    }

    const isMatch = await member.matchPin(pin);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: "Incorrect PIN" });
    }

    res.json({
      success: true,
      message: "PIN verified",
      data: {
        member_id: member.member_id,
        name: member.name,
        role: member.role,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
