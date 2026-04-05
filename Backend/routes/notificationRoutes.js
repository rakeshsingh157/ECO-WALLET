/**
 * ECO Wallet — Notification Routes
 * GET  /api/notifications        — Get user notifications
 * PUT  /api/notifications/:id/read — Mark as read
 * GET  /api/notifications/unread-count
 */
const express = require("express");
const { protect } = require("../middleware/auth");
const Notification = require("../models/Notification");
const User = require("../models/User");

const router = express.Router();

/**
 * @route   GET /api/notifications
 * @desc    Get user's notifications (paginated)
 */
router.get("/", protect, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [notifications, total, unread] = await Promise.all([
      Notification.find({ user_id: req.user.user_id })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Notification.countDocuments({ user_id: req.user.user_id }),
      Notification.countDocuments({ user_id: req.user.user_id, read: false }),
    ]);

    res.json({
      success: true,
      data: {
        notifications: notifications.map((n) => ({
          id: n._id,
          type: n.type,
          title: n.title,
          message: n.message,
          read: n.read,
          timestamp: n.timestamp,
        })),
        unread_count: unread,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
        },
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/notifications/unread-count
 * @desc    Get unread notification count
 */
router.get("/unread-count", protect, async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      user_id: req.user.user_id,
      read: false,
    });
    res.json({ success: true, data: { count } });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   PUT /api/notifications/:id/read
 * @desc    Mark a notification as read
 */
router.put("/:id/read", protect, async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user_id: req.user.user_id },
      { read: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, message: "Notification not found" });
    }

    res.json({ success: true, message: "Marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   PUT /api/notifications/read-all
 * @desc    Mark all notifications as read
 */
router.put("/read-all", protect, async (req, res) => {
  try {
    await Notification.updateMany(
      { user_id: req.user.user_id, read: false },
      { read: true }
    );
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   POST /api/notifications/register-token
 * @desc    Register FCM token
 */
router.post("/register-token", protect, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: "Token required" });
    }

    await User.findOneAndUpdate({ user_id: req.user.user_id }, { fcmToken: token });

    res.json({ success: true, message: "FCM token registered" });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
