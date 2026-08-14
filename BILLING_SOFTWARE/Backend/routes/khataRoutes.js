const express = require("express");
const router = express.Router();
const KhataCustomer = require("../models/KhataCustomer");

// GET /api/khata — Fetch all Khata customers from MongoDB Atlas
router.get("/", async (req, res) => {
  try {
    const customers = await KhataCustomer.find().sort({ updatedAt: -1 });
    const totalDue = customers.reduce((sum, c) => sum + (c.due_amount || 0), 0);
    res.json({ success: true, totalDue, count: customers.length, data: customers });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

// POST /api/khata — Add new Khata customer
router.post("/", async (req, res) => {
  try {
    const { name, phone, address, aadhaar_number, due_amount } = req.body;
    const newCustomer = new KhataCustomer({
      customer_id: `k_${Date.now()}`,
      name,
      phone,
      address,
      aadhaar_number,
      due_amount: Number(due_amount) || 0,
    });
    await newCustomer.save();
    res.status(201).json({ success: true, data: newCustomer });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
