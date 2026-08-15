const express = require("express");
const router = express.Router();
const Customer = require("../models/Customer");
const KhataLedger = require("../models/KhataLedger");

router.get("/", async (req, res) => {
  try {
    const customers = await Customer.find().sort({ due_amount: -1, updatedAt: -1 }).lean();
    const totalDue = customers.reduce((sum, c) => sum + (Number(c.due_amount) || 0), 0);
    const sanitized = customers.map((c) => ({
      ...c,
      id: c.customer_id,
    }));
    res.json({ success: true, totalDue, count: sanitized.length, data: sanitized });
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
    const cleanPhone = phone.trim();

    const customer = await Customer.findOneAndUpdate(
      { phone: cleanPhone },
      {
        $setOnInsert: {
          customer_id: customerId,
          total_spent: 0,
          total_orders: 0,
        },
        $set: {
          name: name.trim(),
          address: address ? address.trim() : "",
          aadhaar_number: aadhaar_number ? aadhaar_number.trim() : "",
          due_amount: Number(due_amount) >= 0 ? Number(due_amount) : 0,
          last_transaction: new Date(),
        },
      },
      { upsert: true, new: true }
    );

    res.status(201).json({ success: true, data: { ...customer.toObject(), id: customer.customer_id } });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post("/:id/transaction", async (req, res) => {
  try {
    const { type, amount, note, bill_id } = req.body;
    const numAmount = Number(amount);

    if (!numAmount || numAmount <= 0) {
      return res.status(400).json({ success: false, message: "Valid transaction amount is required" });
    }

    const query = {
      $or: [
        { customer_id: req.params.id },
        { phone: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    };

    const delta = type === "payment" ? -numAmount : numAmount;

    const customer = await Customer.findOneAndUpdate(
      query,
      {
        $inc: {
          due_amount: delta,
          ...(type === "credit" ? { total_spent: numAmount, total_orders: 1 } : {}),
        },
        $set: { last_transaction: new Date() },
      },
      { new: true }
    );

    if (!customer) {
      return res.status(404).json({ success: false, message: "Khata customer not found" });
    }

    if (customer.due_amount < 0) {
      customer.due_amount = 0;
      await customer.save();
    }

    await KhataLedger.create({
      customer_id: customer.customer_id,
      type: type === "payment" ? "payment" : "credit",
      amount: numAmount,
      bill_id: bill_id || null,
      note: note || (type === "payment" ? "Settlement" : "Credit"),
      date: new Date(),
    });

    res.json({
      success: true,
      data: { ...customer.toObject(), id: customer.customer_id },
      message: `Khata updated. Balance: ${customer.due_amount}`,
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const query = {
      $or: [
        { customer_id: req.params.id },
        { phone: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    };
    const deleted = await Customer.findOneAndDelete(query);
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Customer not found" });
    }
    res.json({ success: true, message: "Khata customer deleted successfully" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
