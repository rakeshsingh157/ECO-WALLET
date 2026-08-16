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
      enum: ["pending", "processing", "completed", "refunded", "partially_refunded", "expired", "failed"],
      default: "pending",
      index: true,
    },
    payer_id: {
      type: String,
      default: null,
    },
    payer_name: {
      type: String,
      default: null,
    },
    transaction_id: {
      type: String,
      default: null,
    },
    refund_status: {
      type: String,
      enum: ["none", "partial", "full"],
      default: "none",
    },
    refunded_amount: {
      type: Number,
      default: 0,
    },
    refund_history: [
      {
        refund_id: { type: String, required: true },
        amount: { type: Number, required: true },
        reason: { type: String, default: "Customer request" },
        created_at: { type: Date, default: Date.now },
      },
    ],
    webhook_delivered: {
      type: Boolean,
      default: false,
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

merchantPaymentSchema.index({ merchant_id: 1, order_id: 1 });
merchantPaymentSchema.index({ status: 1, expires_at: 1 });

module.exports = mongoose.models.MerchantPayment || mongoose.model("MerchantPayment", merchantPaymentSchema);
