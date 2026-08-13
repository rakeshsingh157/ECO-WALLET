/**
 * ECO Wallet — Merchant Model
 * Represents a registered billing software / POS system
 * that can create payment requests and receive webhooks.
 */
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

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
      // Links to an ECO Wallet user (the shop owner)
    },
    business_name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 200,
    },
    webhook_url: {
      type: String,
      required: true,
      trim: true,
      // URL where payment notifications are sent
    },
    webhook_secret: {
      type: String,
      required: true,
      // Shared secret for HMAC signature verification
    },
    api_key_hash: {
      type: String,
      required: true,
      // bcrypt hash of the API key
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

/**
 * Compare API key against stored hash
 */
merchantSchema.methods.matchApiKey = async function (plainKey) {
  return await bcrypt.compare(plainKey, this.api_key_hash);
};

/**
 * Return public-safe merchant data (no secrets)
 */
merchantSchema.methods.toPublic = function () {
  return {
    merchant_id: this.merchant_id,
    user_id: this.user_id,
    business_name: this.business_name,
    webhook_url: this.webhook_url,
    is_active: this.is_active,
    total_payments: this.total_payments,
    total_revenue: this.total_revenue,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model("Merchant", merchantSchema);
