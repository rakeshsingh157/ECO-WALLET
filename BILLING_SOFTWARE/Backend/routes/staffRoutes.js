const express = require("express");
const router = express.Router();
const StaffMember = require("../models/StaffMember");

// GET /api/staff — Fetch staff members from MongoDB Atlas
router.get("/", async (req, res) => {
  try {
    const staff = await StaffMember.find().sort({ createdAt: -1 });
    res.json({ success: true, count: staff.length, data: staff });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

// POST /api/staff — Register staff member
router.post("/", async (req, res) => {
  try {
    const { name, phone, role, pin } = req.body;
    const newMember = new StaffMember({
      member_id: `m_${Date.now()}`,
      name,
      phone,
      role: role || "Staff",
      pin: pin || "0000",
    });
    await newMember.save();
    res.status(201).json({ success: true, data: newMember });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
