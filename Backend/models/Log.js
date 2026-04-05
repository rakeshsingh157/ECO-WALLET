/**
 * ECO Wallet — Audit Log Model
 */
const mongoose = require("mongoose");

const logSchema = new mongoose.Schema({
  action: {
    type: String,
    required: true,
  },
  actor_id: {
    type: String, // user_id or "SYSTEM"
    required: true,
  },
  actor_role: {
    type: String,
    default: "user",
  },
  details: {
    type: String,
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  ip_address: {
    type: String,
    default: null,
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

module.exports = mongoose.model("Log", logSchema);
