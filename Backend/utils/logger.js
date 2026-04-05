/**
 * ECO Wallet — Audit Logger
 * Logs all sensitive actions to MongoDB
 */
const Log = require("../models/Log");

/**
 * Create an audit log entry
 */
const auditLog = async (action, actor_id, details, metadata = {}, ip = null, actor_role = "user") => {
  try {
    await Log.create({
      action,
      actor_id,
      actor_role,
      details,
      metadata,
      ip_address: ip,
      timestamp: new Date(),
    });
  } catch (err) {
    console.error("⚠️ Audit log write failed:", err.message);
  }
};

module.exports = { auditLog };
