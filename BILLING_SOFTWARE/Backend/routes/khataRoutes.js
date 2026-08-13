const express = require("express");
const router = express.Router();
const KhataCustomer = require("../models/KhataCustomer");

const defaultCustomers = [
  { customer_id: "k1", name: "Ramesh Kumar", phone: "+91 98765 43210", address: "Shop 4, Main Market", aadhaar_number: "1234 5678 9012", due_amount: 450 },
  { customer_id: "k2", name: "Suresh Sharma", phone: "+91 98123 45678", address: "Block B, Sector 5", aadhaar_number: "9876 5432 1098", due_amount: 1200 },
  { customer_id: "k3", name: "Anita Verma", phone: "+91 97111 22334", address: "House 12, Gandhi Nagar", aadhaar_number: "4567 8901 2345", due_amount: 650 },
];

// GET /api/khata — Fetch all Khata customers
router.get("/", async (req, res) => {
  try {
    let customers = await KhataCustomer.find().sort({ updatedAt: -1 });
    if (customers.length === 0) {
      customers = await KhataCustomer.insertMany(defaultCustomers);
    }
    const totalDue = customers.reduce((sum, c) => sum + (c.due_amount || 0), 0);
    res.json({ success: true, totalDue, count: customers.length, data: customers });
  } catch (error) {
    res.json({ success: true, totalDue: 2300, count: defaultCustomers.length, data: defaultCustomers });
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
