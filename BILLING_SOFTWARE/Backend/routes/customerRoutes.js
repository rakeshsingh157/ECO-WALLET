const express = require("express");
const router = express.Router();
const Customer = require("../models/Customer");
const KhataLedger = require("../models/KhataLedger");

router.get("/", async (req, res) => {
  try {
    const { search, limit, page, dueOnly } = req.query;
    const query = {};

    if (dueOnly === "true") {
      query.due_amount = { $gt: 0 };
    }

    if (search && search.trim().length > 0) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      query.$or = [
        { name: { $regex: escaped, $options: "i" } },
        { phone: { $regex: escaped, $options: "i" } },
      ];
    }

    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(500, Math.max(1, parseInt(limit) || 100));
    const skip = (pageNum - 1) * limitNum;

    const [customers, totalCount] = await Promise.all([
      Customer.find(query)
        .sort({ due_amount: -1, updatedAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Customer.countDocuments(query),
    ]);

    const sanitized = customers.map((c) => ({
      id: c.customer_id,
      customer_id: c.customer_id,
      name: c.name,
      phone: c.phone,
      address: c.address || "",
      due_amount: c.due_amount || 0,
      total_spent: c.total_spent || 0,
      total_orders: c.total_orders || 0,
      last_transaction: c.last_transaction,
    }));

    res.json({
      success: true,
      count: sanitized.length,
      total: totalCount,
      page: pageNum,
      totalPages: Math.ceil(totalCount / limitNum),
      data: sanitized,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const customer = await Customer.findOne({
      $or: [
        { customer_id: req.params.id },
        { phone: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    }).lean();

    if (!customer) {
      return res.status(404).json({ success: false, message: "Customer not found" });
    }

    res.json({
      success: true,
      data: {
        id: customer.customer_id,
        customer_id: customer.customer_id,
        name: customer.name,
        phone: customer.phone,
        address: customer.address || "",
        due_amount: customer.due_amount || 0,
        total_spent: customer.total_spent || 0,
        total_orders: customer.total_orders || 0,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const { name, phone, address, aadhaar_number, initial_due, customer_id } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Customer name is required" });
    }
    if (!phone || phone.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Customer phone is required" });
    }

    const cleanPhone = phone.trim();
    const customerId = customer_id || `cust_${Date.now()}`;

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
          due_amount: Number(initial_due) >= 0 ? Number(initial_due) : 0,
          last_transaction: new Date(),
        },
      },
      { upsert: true, new: true }
    );

    res.status(201).json({
      success: true,
      data: {
        id: customer.customer_id,
        customer_id: customer.customer_id,
        name: customer.name,
        phone: customer.phone,
        address: customer.address || "",
        due_amount: customer.due_amount || 0,
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post("/:id/credit", async (req, res) => {
  try {
    const { amount, bill_id, note } = req.body;
    const creditAmount = Number(amount);

    if (!creditAmount || creditAmount <= 0) {
      return res.status(400).json({ success: false, message: "Valid credit amount is required" });
    }

    const customer = await Customer.findOneAndUpdate(
      {
        $or: [
          { customer_id: req.params.id },
          { phone: req.params.id },
          ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
        ],
      },
      {
        $inc: { due_amount: creditAmount, total_spent: creditAmount, total_orders: 1 },
        $set: { last_transaction: new Date() },
      },
      { new: true }
    );

    if (!customer) {
      return res.status(404).json({ success: false, message: "Customer not found" });
    }

    await KhataLedger.create({
      customer_id: customer.customer_id,
      type: "credit",
      amount: creditAmount,
      bill_id: bill_id || null,
      note: note || "Khata credit order",
      date: new Date(),
    });

    res.json({
      success: true,
      message: "Khata credit entry recorded",
      due_amount: customer.due_amount,
      data: customer,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/:id/payment", async (req, res) => {
  try {
    const { amount, note } = req.body;
    const paymentAmount = Number(amount);

    if (!paymentAmount || paymentAmount <= 0) {
      return res.status(400).json({ success: false, message: "Valid payment amount is required" });
    }

    const customer = await Customer.findOne({
      $or: [
        { customer_id: req.params.id },
        { phone: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    });

    if (!customer) {
      return res.status(404).json({ success: false, message: "Customer not found" });
    }

    const newDue = Math.max(0, customer.due_amount - paymentAmount);
    customer.due_amount = newDue;
    customer.last_transaction = new Date();
    await customer.save();

    await KhataLedger.create({
      customer_id: customer.customer_id,
      type: "payment",
      amount: paymentAmount,
      note: note || "Khata cash settlement",
      date: new Date(),
    });

    res.json({
      success: true,
      message: "Khata payment received and recorded",
      due_amount: customer.due_amount,
      data: customer,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/:id/ledger", async (req, res) => {
  try {
    const ledger = await KhataLedger.find({ customer_id: req.params.id })
      .sort({ date: -1 })
      .limit(100)
      .lean();

    res.json({ success: true, count: ledger.length, data: ledger });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
