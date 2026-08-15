const express = require("express");
const router = express.Router();
const NotificationItem = require("../models/NotificationItem");
const Product = require("../models/Product");
const KhataCustomer = require("../models/KhataCustomer");

router.get("/", async (req, res) => {
  try {
    let notifications = await NotificationItem.find()
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    if (notifications.length === 0) {
      const lowStockProducts = await Product.find({ stock: { $lte: 5 } }).limit(3).lean();
      for (const p of lowStockProducts) {
        const notifId = `notif_low_${p.product_id || p._id}`;
        await NotificationItem.findOneAndUpdate(
          { notification_id: notifId },
          {
            $set: {
              notification_id: notifId,
              title: "Low Stock Alert",
              message: `${p.name} is running low in stock. Only ${p.stock} ${p.unit || 'pcs'} remaining.`,
              type: "warning",
              is_read: false,
            }
          },
          { upsert: true }
        );
      }

      const highDueCustomers = await KhataCustomer.find({ due_amount: { $gte: 500 } }).limit(2).lean();
      for (const c of highDueCustomers) {
        const notifId = `notif_khata_${c.customer_id || c._id}`;
        await NotificationItem.findOneAndUpdate(
          { notification_id: notifId },
          {
            $set: {
              notification_id: notifId,
              title: "Khata Payment Due",
              message: `${c.name} has a pending credit balance of ₹${c.due_amount}. Tap to send WhatsApp reminder.`,
              type: "info",
              is_read: false,
            }
          },
          { upsert: true }
        );
      }

      notifications = await NotificationItem.find()
        .sort({ createdAt: -1 })
        .limit(50)
        .lean();
    }

    const sanitized = notifications.map((n) => ({
      id: n.notification_id,
      title: n.title,
      message: n.message,
      type: n.type,
      isRead: n.is_read,
      createdAt: n.createdAt,
    }));

    res.json({ success: true, count: sanitized.length, data: sanitized });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.post("/read-all", async (req, res) => {
  try {
    await NotificationItem.updateMany({}, { $set: { is_read: true } });
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/:id/read", async (req, res) => {
  try {
    await NotificationItem.findOneAndUpdate(
      { notification_id: req.params.id },
      { $set: { is_read: true } }
    );
    res.json({ success: true, message: "Notification marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
