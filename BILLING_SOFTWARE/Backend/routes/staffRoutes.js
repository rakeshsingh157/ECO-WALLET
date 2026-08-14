const express = require("express");
const router = express.Router();
const StaffMember = require("../models/StaffMember");

router.get("/", async (req, res) => {
  try {
    const staff = await StaffMember.find().sort({ createdAt: -1 });
    res.json({ success: true, count: staff.length, data: staff });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.post("/", async (req, res) => {
  try {
    const { name, phone, role, pin, member_id } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Staff member name is required" });
    }

    const memberId = member_id || `m_${Date.now()}`;
    const newMember = new StaffMember({
      member_id: memberId,
      name: name.trim(),
      phone: phone ? phone.trim() : "",
      role: role || "Counter Cashier",
      pin: pin || "0000",
    });

    await newMember.save();
    console.log(`[INFO] Staff member added: ${newMember.name}`);
    res.status(201).json({ success: true, data: newMember });
  } catch (error) {
    console.error("[ERROR] Failed to add staff member:", error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const query = {
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
    if (!member_id || !pin) {
      return res.status(400).json({ success: false, message: "Member ID and PIN are required" });
    }

    const member = await StaffMember.findOne({ member_id });
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
