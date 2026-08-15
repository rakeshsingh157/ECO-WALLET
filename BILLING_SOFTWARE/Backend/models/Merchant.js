/**
 * ECO Wallet & Dukaan Dost — Merchant Model
 */
const mongoose = require("mongoose");

const merchantSchema = new mongoose.Schema(
  {
    merchant_id: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    user_id: {
      type: String,
      required: true,
      index: true,
    },
    business_name: {
      type: String,
      required: true,
      trim: true,
    },
    owner_name: {
      type: String,
      trim: true,
    },
    mobile_number: {
      type: String,
      trim: true,
    },
    gstin: {
      type: String,
      trim: true,
      default: "",
    },
    address: {
      type: String,
      trim: true,
      default: "",
    },
    webhook_url: {
      type: String,
      trim: true,
    },
    webhook_secret: {
      type: String,
    },
    api_key_hash: {
      type: String,
    },
    is_active: {
      type: Boolean,
      default: true,
    },
    total_payments: {
      type: Number,
      default: 0,
    },
    total_revenue: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.models.Merchant || mongoose.model("Merchant", merchantSchema);
