const mongoose = require("mongoose");

const NotificationItemSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    notification_id: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    type: {
      type: String,
      enum: ["info", "warning", "success", "danger"],
      default: "info",
      index: true,
    },
    is_read: { type: Boolean, default: false, index: true },
  },
  { timestamps: true }
);

NotificationItemSchema.index({ merchant_id: 1, is_read: 1, createdAt: -1 });

module.exports = mongoose.models.NotificationItem || mongoose.model("NotificationItem", NotificationItemSchema);
