/**
 * ECO Wallet — Merchant Payment Model
 * Tracks individual payment requests created by billing software.
 * Lifecycle: pending → completed | expired | failed
 */
const mongoose = require("mongoose");

const merchantPaymentSchema = new mongoose.Schema(
  {
    payment_id: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    merchant_id: {
      type: String,
      required: true,
      index: true,
    },
    order_id: {
      type: String,
      required: true,
      trim: true,
      // The billing software's own invoice/bill ID
    },
    amount: {
      type: Number,
      required: true,
      min: 0.01,
    },
    description: {
      type: String,
      maxlength: 500,
      default: null,
    },
    status: {
      type: String,
      enum: ["pending", "completed", "expired", "failed"],
      default: "pending",
      index: true,
    },
    payer_id: {
      type: String,
      default: null,
      // Filled when a customer pays
    },
    payer_name: {
      type: String,
      default: null,
    },
    transaction_id: {
      type: String,
      default: null,
      // Links to the ECO Transaction record after payment
    },
    webhook_delivered: {
      type: Boolean,
      default: false,
    },
    webhook_attempts: {
      type: Number,
      default: 0,
    },
    webhook_last_error: {
      type: String,
      default: null,
    },
    expires_at: {
      type: Date,
      required: true,
      index: true,
    },
    completed_at: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index: merchant + order for idempotent lookups
merchantPaymentSchema.index({ merchant_id: 1, order_id: 1 });
// TTL-style index for finding expired payments efficiently
merchantPaymentSchema.index({ status: 1, expires_at: 1 });

module.exports = mongoose.model("MerchantPayment", merchantPaymentSchema);
