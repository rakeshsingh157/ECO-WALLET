const express = require("express");
const router = express.Router();
const Customer = require("../models/Customer");
const KhataLedger = require("../models/KhataLedger");
const Bill = require("../models/Bill");

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
      aadhaar_number: c.aadhaar_number || "",
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
        aadhaar_number: customer.aadhaar_number || "",
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
        aadhaar_number: customer.aadhaar_number || "",
        due_amount: customer.due_amount || 0,
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post("/:id/credit", async (req, res) => {
  try {
    const { amount, bill_id, note, payment_mode } = req.body;
    const creditAmount = Number(amount);

    if (!creditAmount || creditAmount <= 0) {
      return res.status(400).json({ success: false, message: "Valid credit amount is required" });
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

    customer.due_amount = (customer.due_amount || 0) + creditAmount;
    customer.total_spent = (customer.total_spent || 0) + creditAmount;
    customer.total_orders = (customer.total_orders || 0) + 1;
    customer.last_transaction = new Date();
    await customer.save();

    const ledger = await KhataLedger.create({
      customer_id: customer.customer_id,
      type: "credit",
      amount: creditAmount,
      bill_id: bill_id || null,
      note: note || "Khata credit (Udhar)",
      payment_mode: payment_mode || "khata",
      balance_after: customer.due_amount,
      date: new Date(),
    });

    res.json({
      success: true,
      message: "Khata credit entry recorded",
      due_amount: customer.due_amount,
      total_spent: customer.total_spent,
      total_orders: customer.total_orders,
      ledger_entry: ledger,
      data: customer,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/:id/payment", async (req, res) => {
  try {
    const { amount, note, payment_mode } = req.body;
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

    const currentDue = customer.due_amount || 0;
    if (currentDue <= 0) {
      return res.status(400).json({
        success: false,
        message: "Customer has no outstanding due balance to pay",
      });
    }

    if (paymentAmount > currentDue) {
      return res.status(400).json({
        success: false,
        message: `Payment amount (₹${paymentAmount}) cannot exceed outstanding due balance of ₹${currentDue}`,
      });
    }

    const newDue = Math.max(0, currentDue - paymentAmount);
    customer.due_amount = newDue;
    customer.last_transaction = new Date();
    await customer.save();

    let remainingToCover = paymentAmount;
    const pendingBills = await Bill.find({
      $or: [
        { khata_customer_id: customer.customer_id },
        { customer_phone: customer.phone },
        { customer_name: customer.name },
      ],
      status: "pending",
    }).sort({ createdAt: 1 });

    for (const bill of pendingBills) {
      if (remainingToCover <= 0 && newDue > 0) break;
      if (remainingToCover >= bill.total_amount || newDue === 0) {
        bill.status = "completed";
        bill.payment_mode = payment_mode || "cash";
        await bill.save();
        remainingToCover -= bill.total_amount;
      }
    }

    if (newDue === 0) {
      await Bill.updateMany(
        {
          $or: [
            { khata_customer_id: customer.customer_id },
            { customer_phone: customer.phone },
            { customer_name: customer.name },
          ],
          status: "pending",
        },
        {
          $set: {
            status: "completed",
            payment_mode: payment_mode || "cash",
          },
        }
      );
    }

    const ledger = await KhataLedger.create({
      customer_id: customer.customer_id,
      type: "payment",
      amount: paymentAmount,
      note: note || "Khata settlement",
      payment_mode: payment_mode || "cash",
      balance_after: customer.due_amount,
      date: new Date(),
    });

    res.json({
      success: true,
      message: "Khata payment received and recorded",
      due_amount: customer.due_amount,
      total_spent: customer.total_spent,
      total_orders: customer.total_orders,
      ledger_entry: ledger,
      data: customer,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/:id/ledger", async (req, res) => {
  try {
    const customer = await Customer.findOne({
      $or: [
        { customer_id: req.params.id },
        { phone: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    });
    const custId = customer ? customer.customer_id : req.params.id;
    const phone = customer ? customer.phone : req.params.id;

    const ledger = await KhataLedger.find({
      $or: [{ customer_id: custId }, { customer_id: phone }, { customer_id: req.params.id }],
    })
      .sort({ date: -1, createdAt: -1 })
      .limit(100)
      .lean();

    res.json({ success: true, count: ledger.length, data: ledger });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/:id/transactions", async (req, res) => {
  try {
    const customer = await Customer.findOne({
      $or: [
        { customer_id: req.params.id },
        { phone: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    });

    const custId = customer ? customer.customer_id : req.params.id;
    const phone = customer ? customer.phone : req.params.id;

    const [ledgerEntries, bills] = await Promise.all([
      KhataLedger.find({
        $or: [{ customer_id: custId }, { customer_id: phone }, { customer_id: req.params.id }],
      })
        .sort({ date: -1, createdAt: -1 })
        .limit(100)
        .lean(),
      Bill.find({
        $or: [
          { khata_customer_id: custId },
          { khata_customer_id: req.params.id },
          { customer_phone: phone },
          { customer_phone: req.params.id },
        ],
      })
        .sort({ createdAt: -1 })
        .limit(100)
        .lean(),
    ]);

    const combined = [];
    for (const b of bills) {
      combined.push({
        id: b.bill_id,
        type: "bill",
        title: `Store Bill #${b.bill_id.substring(0, b.bill_id.length > 10 ? 10 : b.bill_id.length).toUpperCase()}`,
        subtitle: `${b.items ? b.items.length : 0} items • ${b.payment_mode ? b.payment_mode.toUpperCase() : "PAID"}`,
        amount: b.total_amount,
        refunded_amount: b.refunded_amount || 0,
        net_amount: Math.max(0, (b.total_amount || 0) - (b.refunded_amount || 0)),
        status: b.status,
        payment_mode: b.payment_mode,
        date: b.createdAt ? new Date(b.createdAt).toISOString() : new Date().toISOString(),
      });
    }
    for (const l of ledgerEntries) {
      combined.push({
        id: l._id.toString(),
        type: l.type,
        title: l.type === "credit" ? "Khata Credit (Udhar)" : "Payment Received",
        subtitle: l.note || (l.type === "credit" ? "Store goods credit" : "Khata settlement"),
        amount: l.amount,
        balance_after: l.balance_after,
        payment_mode: l.payment_mode || (l.type === "credit" ? "Khata" : "Cash"),
        date: l.date ? new Date(l.date).toISOString() : (l.createdAt ? new Date(l.createdAt).toISOString() : new Date().toISOString()),
      });
    }

    combined.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    res.json({ success: true, count: combined.length, data: combined });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

module.exports = router;
