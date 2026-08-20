const express = require("express");
const router = express.Router();
const NotificationItem = require("../models/NotificationItem");
const Product = require("../models/Product");
const Customer = require("../models/Customer");

router.get("/", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    let notifications = await NotificationItem.find({ merchant_id: merchantId })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    if (notifications.length === 0) {
      const lowStockProducts = await Product.find({ merchant_id: merchantId, stock: { $lte: 5 } }).limit(3).lean();
      for (const p of lowStockProducts) {
        const notifId = `notif_low_${p.product_id || p._id}`;
        await NotificationItem.findOneAndUpdate(
          { merchant_id: merchantId, notification_id: notifId },
          {
            $set: {
              merchant_id: merchantId,
              notification_id: notifId,
              title: "Low Stock Alert",
              message: `${p.name} is running low in stock. Only ${p.stock} ${p.unit || "pcs"} remaining.`,
              type: "warning",
              is_read: false,
            },
          },
          { upsert: true }
        );
      }

      const highDueCustomers = await Customer.find({ merchant_id: merchantId, due_amount: { $gte: 500 } }).limit(2).lean();
      for (const c of highDueCustomers) {
        const notifId = `notif_khata_${c.customer_id || c._id}`;
        await NotificationItem.findOneAndUpdate(
          { merchant_id: merchantId, notification_id: notifId },
          {
            $set: {
              merchant_id: merchantId,
              notification_id: notifId,
              title: "Khata Payment Due",
              message: `${c.name} has a pending credit balance of ₹${c.due_amount}. Tap to send WhatsApp reminder.`,
              type: "info",
              is_read: false,
            },
          },
          { upsert: true }
        );
      }

      notifications = await NotificationItem.find({ merchant_id: merchantId })
        .sort({ createdAt: -1 })
        .limit(50)
        .lean();
    }

    const sanitized = notifications.map((n) => ({
      id: n.notification_id,
      title: n.title,
      message: n.message,
      type: n.type,
      is_read: n.is_read,
      createdAt: n.createdAt,
    }));

    const unreadCount = sanitized.filter((n) => !n.is_read).length;

    res.json({
      success: true,
      count: sanitized.length,
      unreadCount,
      data: sanitized,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.put("/:id/read", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const notification = await NotificationItem.findOneAndUpdate(
      { merchant_id: merchantId, notification_id: req.params.id },
      { $set: { is_read: true } },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ success: false, message: "Notification not found" });
    }
    res.json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.put("/read-all", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    await NotificationItem.updateMany(
      { merchant_id: merchantId, is_read: false },
      { $set: { is_read: true } }
    );
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
