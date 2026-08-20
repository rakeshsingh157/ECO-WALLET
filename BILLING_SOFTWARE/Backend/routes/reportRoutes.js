const express = require("express");
const router = express.Router();
const Bill = require("../models/Bill");
const Expense = require("../models/Expense");
const Product = require("../models/Product");

function getStartOfTodayIST() {
  const now = new Date();
  const istTime = new Date(now.getTime() + 330 * 60 * 1000);
  const istYear = istTime.getUTCFullYear();
  const istMonth = istTime.getUTCMonth();
  const istDate = istTime.getUTCDate();
  return new Date(Date.UTC(istYear, istMonth, istDate) - 330 * 60 * 1000);
}

router.get("/summary", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const startOfToday = getStartOfTodayIST();

    const [todaySalesAgg, totalSalesAgg, todayExpensesAgg, totalExpensesAgg, billCount, productCount] = await Promise.all([
      Bill.aggregate([
        { $match: { merchant_id: merchantId, createdAt: { $gte: startOfToday }, status: "completed" } },
        { $group: { _id: null, total: { $sum: "$total_amount" }, count: { $sum: 1 } } },
      ]),
      Bill.aggregate([
        { $match: { merchant_id: merchantId, status: "completed" } },
        { $group: { _id: null, total: { $sum: "$total_amount" }, count: { $sum: 1 } } },
      ]),
      Expense.aggregate([
        { $match: { merchant_id: merchantId, date: { $gte: startOfToday } } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
      Expense.aggregate([
        { $match: { merchant_id: merchantId } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
      Bill.countDocuments({ merchant_id: merchantId, status: "completed" }),
      Product.countDocuments({ merchant_id: merchantId }),
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
    const merchantId = req.merchant_id || "mch_default";
    const topProducts = await Bill.aggregate([
      { $match: { merchant_id: merchantId, status: "completed" } },
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
