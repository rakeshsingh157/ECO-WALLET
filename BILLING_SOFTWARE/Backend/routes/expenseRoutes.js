const express = require("express");
const router = express.Router();
const Expense = require("../models/Expense");

function getISTDateRange(period) {
  const now = new Date();
  const istTime = new Date(now.getTime() + 330 * 60 * 1000);
  const istYear = istTime.getUTCFullYear();
  const istMonth = istTime.getUTCMonth();
  const istDate = istTime.getUTCDate();
  const istDay = istTime.getUTCDay();

  const startOfToday = new Date(Date.UTC(istYear, istMonth, istDate) - 330 * 60 * 1000);

  if (period === "today") {
    return startOfToday;
  } else if (period === "this_week") {
    const diff = istDate - istDay + (istDay === 0 ? -6 : 1);
    return new Date(Date.UTC(istYear, istMonth, diff) - 330 * 60 * 1000);
  } else if (period === "this_month") {
    return new Date(Date.UTC(istYear, istMonth, 1) - 330 * 60 * 1000);
  }
  return startOfToday;
}

router.get("/", async (req, res) => {
  try {
    const { category, period, limit, page } = req.query;
    const merchantId = req.merchant_id || "mch_default";
    const query = { merchant_id: merchantId };

    if (category && category !== "All") {
      query.category = category;
    }

    if (period === "today") {
      query.date = { $gte: getISTDateRange("today") };
    } else if (period === "this_week") {
      query.date = { $gte: getISTDateRange("this_week") };
    } else if (period === "this_month") {
      query.date = { $gte: getISTDateRange("this_month") };
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
    const merchantId = req.merchant_id || req.body.merchant_id || "mch_default";
    const { title, amount, category, payment_mode, paymentMode, notes, expense_id } = req.body;

    if (!title || title.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Expense title is required" });
    }
    if (amount === undefined || Number(amount) <= 0) {
      return res.status(400).json({ success: false, message: "Valid expense amount is required" });
    }

    const expenseId = expense_id || `exp_${Date.now()}`;
    const newExpense = new Expense({
      merchant_id: merchantId,
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

router.put("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const { title, amount, category, payment_mode, paymentMode, notes } = req.body;
    const query = {
      merchant_id: merchantId,
      $or: [
        { expense_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    };

    const updateData = {};
    if (title) updateData.title = title.trim();
    if (amount !== undefined) updateData.amount = Number(amount);
    if (category) updateData.category = category;
    if (payment_mode || paymentMode) updateData.payment_mode = payment_mode || paymentMode;
    if (notes !== undefined) updateData.notes = notes ? notes.trim() : "";

    const updated = await Expense.findOneAndUpdate(query, { $set: updateData }, { new: true });
    if (!updated) {
      return res.status(404).json({ success: false, message: "Expense not found" });
    }

    res.json({
      success: true,
      message: "Expense updated successfully",
      data: {
        id: updated.expense_id,
        expense_id: updated.expense_id,
        title: updated.title,
        amount: updated.amount,
        category: updated.category,
        payment_mode: updated.payment_mode,
        paymentMode: updated.payment_mode,
        notes: updated.notes,
        date: updated.date,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const query = {
      merchant_id: merchantId,
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
