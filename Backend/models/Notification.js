/**
 * ECO Wallet — Notification Model
 */
const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema({
  user_id: {
    type: String,
    required: true,
    index: true,
  },
  type: {
    type: String,
    enum: ["transaction", "reward", "system", "alert"],
    default: "system",
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  read: {
    type: Boolean,
    default: false,
  },
  data: {
    type: mongoose.Schema.Types.Mixed, // Extra payload
    default: null,
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

notificationSchema.index({ user_id: 1, timestamp: -1 });

module.exports = mongoose.model("Notification", notificationSchema);
