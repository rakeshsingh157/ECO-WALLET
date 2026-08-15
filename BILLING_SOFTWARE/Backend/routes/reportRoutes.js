const express = require("express");
const router = express.Router();
const Bill = require("../models/Bill");
const Expense = require("../models/Expense");
const Product = require("../models/Product");

router.get("/summary", async (req, res) => {
  try {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const [todaySalesAgg, totalSalesAgg, todayExpensesAgg, totalExpensesAgg, billCount, productCount] = await Promise.all([
      Bill.aggregate([
        { $match: { createdAt: { $gte: startOfToday }, status: "completed" } },
        { $group: { _id: null, total: { $sum: "$total_amount" }, count: { $sum: 1 } } },
      ]),
      Bill.aggregate([
        { $match: { status: "completed" } },
        { $group: { _id: null, total: { $sum: "$total_amount" }, count: { $sum: 1 } } },
      ]),
      Expense.aggregate([
        { $match: { date: { $gte: startOfToday } } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
      Expense.aggregate([
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
      Bill.countDocuments({ status: "completed" }),
      Product.countDocuments(),
    ]);

    const todaySales = todaySalesAgg.length > 0 ? todaySalesAgg[0].total : 0;
    const todayBillCount = todaySalesAgg.length > 0 ? todaySalesAgg[0].count : 0;
    const grossSales = totalSalesAgg.length > 0 ? totalSalesAgg[0].total : 0;
    const todayExpenses = todayExpensesAgg.length > 0 ? todayExpensesAgg[0].total : 0;
    const totalExpenses = totalExpensesAgg.length > 0 ? totalExpensesAgg[0].total : 0;
    const netProfit = grossSales - totalExpenses;

    res.json({
      success: true,
      data: {
        todaySales,
        todayBillCount,
        grossSales,
        todayExpenses,
        totalExpenses,
        netProfit,
        totalBills: billCount,
        totalProducts: productCount,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/top-products", async (req, res) => {
  try {
    const topProducts = await Bill.aggregate([
      { $match: { status: "completed" } },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.name",
          totalQuantity: { $sum: "$items.quantity" },
          totalRevenue: { $sum: { $multiply: ["$items.price", "$items.quantity"] } },
        },
      },
      { $sort: { totalRevenue: -1 } },
      { $limit: 10 },
    ]);

    res.json({ success: true, count: topProducts.length, data: topProducts });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
