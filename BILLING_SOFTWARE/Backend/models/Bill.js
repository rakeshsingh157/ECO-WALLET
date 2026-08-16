const mongoose = require("mongoose");

const BillItemSchema = new mongoose.Schema({
  product_id: { type: String, required: true },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true, default: 1 },
  unit: { type: String, default: "pcs" },
  returned_quantity: { type: Number, default: 0 },
});

const ReturnHistorySchema = new mongoose.Schema({
  return_id: { type: String, required: true },
  amount: { type: Number, required: true },
  reason: { type: String, default: "Customer Return" },
  items: [{
    product_id: { type: String },
    name: { type: String },
    quantity: { type: Number },
    price: { type: Number },
  }],
  refund_mode: { type: String, default: "cash" },
  timestamp: { type: Date, default: Date.now },
});

const BillSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    bill_id: { type: String, required: true, unique: true, index: true },
    items: [BillItemSchema],
    total_amount: { type: Number, required: true, min: 0 },
    refunded_amount: { type: Number, default: 0, min: 0 },
    payment_mode: {
      type: String,
      enum: ["cash", "upi", "ecoWallet", "pending"],
      required: true,
      default: "cash",
      index: true,
    },
    customer_name: { type: String, trim: true },
    customer_phone: { type: String, trim: true, index: true },
    khata_customer_id: { type: String, index: true },
    status: {
      type: String,
      enum: ["completed", "pending", "failed", "cancelled", "returned", "partially_returned"],
      default: "completed",
      index: true,
    },
    return_history: [ReturnHistorySchema],
    payment_id: { type: String, index: true },
    notes: { type: String },
  },
  { timestamps: true }
);

BillSchema.index({ merchant_id: 1, createdAt: -1 });
BillSchema.index({ merchant_id: 1, payment_mode: 1 });
BillSchema.index({ merchant_id: 1, status: 1 });
BillSchema.index({ merchant_id: 1, total_amount: -1 });

module.exports = mongoose.models.Bill || mongoose.model("Bill", BillSchema);
