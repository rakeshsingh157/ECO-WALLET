const express = require("express");
const router = express.Router();
const KhataCustomer = require("../models/KhataCustomer");

router.get("/", async (req, res) => {
  try {
    const customers = await KhataCustomer.find().sort({ updatedAt: -1 });
    const totalDue = customers.reduce((sum, c) => sum + (Number(c.due_amount) || 0), 0);
    res.json({ success: true, totalDue, count: customers.length, data: customers });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, totalDue: 0, data: [] });
  }
});

router.post("/", async (req, res) => {
  try {
    const { name, phone, address, aadhaar_number, due_amount, customer_id } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Customer name is required" });
    }
    if (!phone || phone.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Customer phone number is required" });
    }

    const customerId = customer_id || `k_${Date.now()}`;
    const newCustomer = new KhataCustomer({
      customer_id: customerId,
      name: name.trim(),
      phone: phone.trim(),
      address: address ? address.trim() : null,
      aadhaar_number: aadhaar_number ? aadhaar_number.trim() : null,
      due_amount: Number(due_amount) || 0,
    });

    await newCustomer.save();
    console.log(`[INFO] Customer added to Khata: ${newCustomer.name}`);
    res.status(201).json({ success: true, data: newCustomer });
  } catch (error) {
    console.error("[ERROR] Failed to add Khata customer:", error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post("/:id/transaction", async (req, res) => {
  try {
    const { type, amount } = req.body;
    const numAmount = Number(amount);

    if (!numAmount || numAmount <= 0) {
      return res.status(400).json({ success: false, message: "Valid transaction amount is required" });
    }

    const delta = type === "payment" ? -numAmount : numAmount;
    const query = {
      $or: [{ customer_id: req.params.id }, { _id: req.params.id.match(/^[0-9a-fA-F]{24}$/) ? req.params.id : null }],
    };

    const customer = await KhataCustomer.findOneAndUpdate(
      query,
      {
        $inc: { due_amount: delta },
        $set: { updatedAt: new Date() },
      },
      { new: true }
    );

    if (!customer) {
      return res.status(404).json({ success: false, message: "Khata customer not found" });
    }

    res.json({ success: true, data: customer, message: `Khata updated. Balance: ${customer.due_amount}` });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const query = {
      $or: [{ customer_id: req.params.id }, { _id: req.params.id.match(/^[0-9a-fA-F]{24}$/) ? req.params.id : null }],
    };
    const deleted = await KhataCustomer.findOneAndDelete(query);
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Customer not found" });
    }
    res.json({ success: true, message: "Khata customer deleted successfully" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
