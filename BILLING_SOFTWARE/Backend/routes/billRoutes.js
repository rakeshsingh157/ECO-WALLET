const express = require("express");
const router = express.Router();
const Bill = require("../models/Bill");
const Product = require("../models/Product");
const Customer = require("../models/Customer");
const KhataLedger = require("../models/KhataLedger");

router.get("/", async (req, res) => {
  try {
    const { period, payment_mode, search, limit, page, status } = req.query;
    const query = {};

    if (payment_mode) {
      query.payment_mode = payment_mode;
    }

    if (status) {
      query.status = status;
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
        { $match: { createdAt: { $gte: startOfToday }, status: { $in: ["completed", "partially_returned"] } } },
        {
          $group: {
            _id: null,
            total: { $sum: { $subtract: ["$total_amount", { $ifNull: ["$refunded_amount", 0] }] } },
            count: { $sum: 1 },
          },
        },
      ]),
      Bill.aggregate([
        { $match: { status: { $in: ["completed", "partially_returned"] } } },
        {
          $group: {
            _id: null,
            total: { $sum: { $subtract: ["$total_amount", { $ifNull: ["$refunded_amount", 0] }] } },
          },
        },
      ]),
    ]);

    const todaySales = todayBillsAgg.length > 0 ? Math.max(0, todayBillsAgg[0].total) : 0;
    const todayBillCount = todayBillsAgg.length > 0 ? todayBillsAgg[0].count : 0;
    const totalSales = totalSalesAgg.length > 0 ? Math.max(0, totalSalesAgg[0].total) : 0;

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

router.post("/return", async (req, res) => {
  try {
    const { bill_id, return_type, returned_items, reason, refund_mode } = req.body;

    if (!bill_id) {
      return res.status(400).json({ success: false, message: "bill_id is required" });
    }

    const cleanBillId = bill_id.trim();
    const bill = await Bill.findOne({
      $or: [
        { bill_id: cleanBillId },
        { bill_id: `BILL_${cleanBillId}` },
        { bill_id: `BILL-${cleanBillId}` },
        ...(cleanBillId.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: cleanBillId }] : []),
      ],
    });

    if (!bill) {
      return res.status(404).json({ success: false, message: `Bill with ID "${bill_id}" not found` });
    }

    const alreadyRefunded = bill.refunded_amount || 0;
    const maxRefundable = Math.max(0, bill.total_amount - alreadyRefunded);

    if (bill.status === "returned" || maxRefundable <= 0) {
      const lastReturn = (bill.return_history && bill.return_history.length > 0)
        ? bill.return_history[bill.return_history.length - 1]
        : null;
      const dateText = lastReturn ? new Date(lastReturn.timestamp).toLocaleString("en-IN") : new Date(bill.updatedAt).toLocaleString("en-IN");
      return res.status(400).json({
        success: false,
        message: `Order #${bill.bill_id} is already 100% refunded (Total ₹${alreadyRefunded.toFixed(2)} refunded on ${dateText}). Further returns are not permitted.`,
        data: {
          bill_id: bill.bill_id,
          status: "returned",
          refunded_amount: alreadyRefunded,
          total_amount: bill.total_amount,
          return_history: bill.return_history,
        }
      });
    }

    let refundAmount = 0;
    const returnHistoryItems = [];
    const stockRestorations = [];

    if (return_type === "partial" && Array.isArray(returned_items) && returned_items.length > 0) {
      for (const item of returned_items) {
        const matchingBillItem = bill.items.find(
          (i) => i.product_id === item.product_id || i.name === item.name
        );
        const requestedQty = Number(item.quantity) || 0;
        const alreadyItemReturned = matchingBillItem ? (matchingBillItem.returned_quantity || 0) : 0;
        const originalItemQty = matchingBillItem ? matchingBillItem.quantity : requestedQty;
        const availableItemReturnQty = Math.max(0, originalItemQty - alreadyItemReturned);

        const qtyToReturn = Math.min(requestedQty, availableItemReturnQty);
        const itemPrice = matchingBillItem ? matchingBillItem.price : (Number(item.price) || 0);

        if (qtyToReturn > 0) {
          const itemRefund = qtyToReturn * itemPrice;
          refundAmount += itemRefund;

          returnHistoryItems.push({
            product_id: item.product_id,
            name: item.name || (matchingBillItem ? matchingBillItem.name : "Item"),
            quantity: qtyToReturn,
            price: itemPrice,
          });

          if (matchingBillItem) {
            matchingBillItem.returned_quantity = (matchingBillItem.returned_quantity || 0) + qtyToReturn;
          }

          if (item.product_id) {
            stockRestorations.push({
              updateOne: {
                filter: { $or: [{ product_id: item.product_id }, { id: item.product_id }] },
                update: { $inc: { stock: qtyToReturn } },
              },
            });
          }
        }
      }
    } else {
      refundAmount = maxRefundable;

      for (const item of bill.items) {
        const remainingQty = Math.max(0, item.quantity - (item.returned_quantity || 0));
        if (remainingQty > 0) {
          returnHistoryItems.push({
            product_id: item.product_id,
            name: item.name,
            quantity: remainingQty,
            price: item.price,
          });
          item.returned_quantity = item.quantity;
          if (item.product_id) {
            stockRestorations.push({
              updateOne: {
                filter: { $or: [{ product_id: item.product_id }, { id: item.product_id }] },
                update: { $inc: { stock: remainingQty } },
              },
            });
          }
        }
      }
    }

    if (refundAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: "No eligible remaining quantities found for return. All selected items have already been returned."
      });
    }

    refundAmount = Math.min(refundAmount, maxRefundable);
    const returnId = `RET_${Date.now()}`;
    const newRefundedTotal = alreadyRefunded + refundAmount;
    const isFullyReturned = newRefundedTotal >= bill.total_amount;

    bill.refunded_amount = newRefundedTotal;
    bill.status = isFullyReturned ? "returned" : "partially_returned";
    bill.return_history = bill.return_history || [];
    bill.return_history.push({
      return_id: returnId,
      amount: refundAmount,
      reason: reason || "Customer Return",
      items: returnHistoryItems,
      refund_mode: refund_mode || bill.payment_mode || "cash",
      timestamp: new Date(),
    });

    await bill.save();

    if (stockRestorations.length > 0) {
      try {
        await Product.bulkWrite(stockRestorations);
      } catch (stockErr) {
        console.error("Stock restore error:", stockErr.message);
      }
    }

    if (bill.customer_phone && bill.customer_phone.trim().length >= 10) {
      try {
        await Customer.findOneAndUpdate(
          { phone: bill.customer_phone.trim() },
          {
            $inc: {
              total_spent: -refundAmount,
              ...(bill.payment_mode === "pending" ? { due_amount: -refundAmount } : {}),
            },
          }
        );
      } catch (_) {}
    }

    res.json({
      success: true,
      message: `Successfully processed refund of ₹${refundAmount.toFixed(2)} for Bill #${bill.bill_id}`,
      data: {
        bill_id: bill.bill_id,
        return_id: returnId,
        refund_amount: refundAmount,
        total_refunded: newRefundedTotal,
        net_bill_amount: Math.max(0, bill.total_amount - newRefundedTotal),
        status: bill.status,
        returned_items: returnHistoryItems,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const {
      items,
      total_amount,
      payment_mode,
      customer_name,
      customer_phone,
      khata_customer_id,
      bill_id,
      shop_name,
      owner_name,
      shop_phone,
      shop_address,
      shop_gstin,
      merchant_id,
    } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: "Bill must contain at least one item" });
    }

    const billId = bill_id || `BILL_${Date.now()}`;
    const billData = {
      bill_id: billId,
      merchant_id: merchant_id || "mch_default",
      shop_name: shop_name || "Dukaan Dost Retail Store",
      owner_name: owner_name || "Store Merchant",
      shop_phone: shop_phone || null,
      shop_address: shop_address || null,
      shop_gstin: shop_gstin || null,
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
      const cust = await Customer.findOneAndUpdate(
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
            due_amount: (payment_mode === "pending" || payment_mode === "khata") ? Number(total_amount) || 0 : 0,
          },
        },
        { upsert: true, new: true }
      );

      if (cust && (payment_mode === "pending" || payment_mode === "khata")) {
        await KhataLedger.create({
          customer_id: cust.customer_id,
          type: "credit",
          amount: Number(total_amount) || 0,
          bill_id: billId,
          note: `Store Bill #${billId.substring(0, billId.length > 10 ? 10 : billId.length).toUpperCase()}`,
          payment_mode: "khata",
          balance_after: cust.due_amount,
          date: new Date(),
        });
      }
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
