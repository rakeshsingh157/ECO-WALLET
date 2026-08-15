const express = require("express");
const router = express.Router();
const Expense = require("../models/Expense");

router.get("/", async (req, res) => {
  try {
    const { category, period, limit, page } = req.query;
    const query = {};

    if (category && category !== "All") {
      query.category = category;
    }

    const now = new Date();
    if (period === "today") {
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      query.date = { $gte: startOfDay };
    } else if (period === "this_week") {
      const day = now.getDay();
      const diff = now.getDate() - day + (day === 0 ? -6 : 1);
      const startOfWeek = new Date(now.setDate(diff));
      startOfWeek.setHours(0, 0, 0, 0);
      query.date = { $gte: startOfWeek };
    } else if (period === "this_month") {
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      query.date = { $gte: startOfMonth };
    }

    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(500, Math.max(1, parseInt(limit) || 100));
    const skip = (pageNum - 1) * limitNum;

    const [expenses, totalCount, totalSum] = await Promise.all([
      Expense.find(query)
        .sort({ date: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Expense.countDocuments(query),
      Expense.aggregate([
        { $match: query },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
    ]);

    const totalAmount = totalSum.length > 0 ? totalSum[0].total : 0;

    const sanitized = expenses.map((e) => ({
      id: e.expense_id,
      expense_id: e.expense_id,
      title: e.title,
      amount: e.amount,
      category: e.category,
      payment_mode: e.payment_mode || "Cash",
      paymentMode: e.payment_mode || "Cash",
      notes: e.notes || "",
      date: e.date,
    }));

    res.json({
      success: true,
      count: sanitized.length,
      total: totalCount,
      totalAmount,
      page: pageNum,
      totalPages: Math.ceil(totalCount / limitNum),
      data: sanitized,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.post("/", async (req, res) => {
  try {
    const { title, amount, category, payment_mode, paymentMode, notes, expense_id } = req.body;

    if (!title || title.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Expense title is required" });
    }
    if (amount === undefined || Number(amount) <= 0) {
      return res.status(400).json({ success: false, message: "Valid expense amount is required" });
    }

    const expenseId = expense_id || `exp_${Date.now()}`;
    const newExpense = new Expense({
      expense_id: expenseId,
      title: title.trim(),
      amount: Number(amount),
      category: category || "Utilities",
      payment_mode: payment_mode || paymentMode || "Cash",
      notes: notes ? notes.trim() : "",
      date: new Date(),
    });

    await newExpense.save();

    res.status(201).json({
      success: true,
      data: {
        id: newExpense.expense_id,
        expense_id: newExpense.expense_id,
        title: newExpense.title,
        amount: newExpense.amount,
        category: newExpense.category,
        payment_mode: newExpense.payment_mode,
        paymentMode: newExpense.payment_mode,
        notes: newExpense.notes,
        date: newExpense.date,
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const query = {
      $or: [
        { expense_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    };
    const deleted = await Expense.findOneAndDelete(query);
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Expense not found" });
    }
    res.json({ success: true, message: "Expense deleted successfully", data: deleted });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
