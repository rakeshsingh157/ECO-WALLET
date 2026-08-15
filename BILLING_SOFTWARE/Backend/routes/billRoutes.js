const express = require("express");
const router = express.Router();
const Bill = require("../models/Bill");
const Product = require("../models/Product");
const Customer = require("../models/Customer");

router.get("/", async (req, res) => {
  try {
    const { period, payment_mode, search, limit, page } = req.query;
    const query = {};

    if (payment_mode) {
      query.payment_mode = payment_mode;
    }

    const now = new Date();
    if (period === "today") {
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      query.createdAt = { $gte: startOfDay };
    } else if (period === "this_week") {
      const day = now.getDay();
      const diff = now.getDate() - day + (day === 0 ? -6 : 1);
      const startOfWeek = new Date(now.setDate(diff));
      startOfWeek.setHours(0, 0, 0, 0);
      query.createdAt = { $gte: startOfWeek };
    } else if (period === "this_month") {
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      query.createdAt = { $gte: startOfMonth };
    }

    if (search && search.trim().length > 0) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      query.$or = [
        { bill_id: { $regex: escaped, $options: "i" } },
        { customer_name: { $regex: escaped, $options: "i" } },
        { customer_phone: { $regex: escaped, $options: "i" } },
      ];
    }

    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(500, Math.max(1, parseInt(limit) || 100));
    const skip = (pageNum - 1) * limitNum;

    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const [bills, totalCount, todayBillsAgg, totalSalesAgg] = await Promise.all([
      Bill.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Bill.countDocuments(query),
      Bill.aggregate([
        { $match: { createdAt: { $gte: startOfToday }, status: "completed" } },
        { $group: { _id: null, total: { $sum: "$total_amount" }, count: { $sum: 1 } } },
      ]),
      Bill.aggregate([
        { $match: { status: "completed" } },
        { $group: { _id: null, total: { $sum: "$total_amount" } } },
      ]),
    ]);

    const todaySales = todayBillsAgg.length > 0 ? todayBillsAgg[0].total : 0;
    const todayBillCount = todayBillsAgg.length > 0 ? todayBillsAgg[0].count : 0;
    const totalSales = totalSalesAgg.length > 0 ? totalSalesAgg[0].total : 0;

    const sanitized = bills.map((b) => ({
      ...b,
      id: b.bill_id || b._id,
      billId: b.bill_id || b._id,
    }));

    res.json({
      success: true,
      todaySales,
      todayBillCount,
      totalSales,
      totalBillCount: totalCount,
      count: sanitized.length,
      page: pageNum,
      totalPages: Math.ceil(totalCount / limitNum),
      data: sanitized,
    });
  } catch (error) {
    res.status(500).json({ success: false, todaySales: 0, todayBillCount: 0, data: [], error: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const { items, total_amount, payment_mode, customer_name, customer_phone, khata_customer_id, bill_id } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: "Bill must contain at least one item" });
    }

    const billId = bill_id || `BILL_${Date.now()}`;
    const billData = {
      bill_id: billId,
      items: items.map((item) => ({
        product_id: item.product_id || item.id || `p_${Date.now()}`,
        name: item.name || "Item",
        price: Number(item.price) || 0,
        quantity: Number(item.quantity) || 1,
        unit: item.unit || "pcs",
      })),
      total_amount: Number(total_amount) || 0,
      payment_mode: payment_mode || "cash",
      customer_name: customer_name || "Counter Customer",
      customer_phone: customer_phone || null,
      khata_customer_id: khata_customer_id || null,
      status: payment_mode === "pending" ? "pending" : "completed",
    };

    const savedBill = await Bill.findOneAndUpdate(
      { bill_id: billId },
      { $set: billData },
      { upsert: true, new: true }
    );

    const bulkOps = savedBill.items
      .filter((i) => i.product_id)
      .map((item) => ({
        updateOne: {
          filter: { product_id: item.product_id },
          update: { $inc: { stock: -item.quantity } },
        },
      }));

    if (bulkOps.length > 0) {
      await Product.bulkWrite(bulkOps);
      await Product.updateMany({ stock: { $lt: 0 } }, { $set: { stock: 0 } });
    }

    if (customer_phone && customer_phone.trim().length >= 10) {
      await Customer.findOneAndUpdate(
        { phone: customer_phone.trim() },
        {
          $setOnInsert: { customer_id: `cust_${Date.now()}` },
          $set: {
            name: customer_name || "Customer",
            last_transaction: new Date(),
          },
          $inc: {
            total_spent: Number(total_amount) || 0,
            total_orders: 1,
            due_amount: payment_mode === "pending" ? Number(total_amount) || 0 : 0,
          },
        },
        { upsert: true }
      );
    }

    res.status(201).json({
      success: true,
      data: {
        ...savedBill.toObject(),
        id: savedBill.bill_id,
        billId: savedBill.bill_id,
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const bill = await Bill.findOne({
      $or: [
        { bill_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    }).lean();

    if (!bill) {
      return res.status(404).json({ success: false, message: "Bill not found" });
    }

    res.json({
      success: true,
      data: {
        ...bill,
        id: bill.bill_id,
        billId: bill.bill_id,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
