const express = require("express");
const router = express.Router();
const StaffMember = require("../models/StaffMember");

const defaultStaff = [
  { member_id: "m1", name: "Sharma Ji (Owner)", phone: "+91 98765 00000", role: "Owner", pin: "1234" },
  { member_id: "m2", name: "Rahul Verma", phone: "+91 98765 11111", role: "Cashier", pin: "5678" },
];

// GET /api/staff — Fetch staff members
router.get("/", async (req, res) => {
  try {
    let staff = await StaffMember.find().sort({ createdAt: -1 });
    if (staff.length === 0) {
      staff = await StaffMember.insertMany(defaultStaff);
    }
    res.json({ success: true, count: staff.length, data: staff });
  } catch (error) {
    res.json({ success: true, count: defaultStaff.length, data: defaultStaff });
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
      role: role || "Cashier",
      pin: pin || "1234",
    });
    await newMember.save();
    res.status(201).json({ success: true, data: newMember });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
