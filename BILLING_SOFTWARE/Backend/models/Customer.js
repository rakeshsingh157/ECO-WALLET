const mongoose = require("mongoose");

const CustomerSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    customer_id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true, index: true },
    phone: { type: String, required: true, trim: true, index: true },
    address: { type: String, trim: true },
    aadhaar_number: { type: String, trim: true },
    due_amount: { type: Number, required: true, default: 0, index: true },
    total_spent: { type: Number, required: true, default: 0 },
    total_orders: { type: Number, required: true, default: 0 },
    last_transaction: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

CustomerSchema.index({ merchant_id: 1, phone: 1 });
CustomerSchema.index({ merchant_id: 1, due_amount: -1 });
CustomerSchema.index({ merchant_id: 1, total_spent: -1 });

module.exports = mongoose.models.Customer || mongoose.model("Customer", CustomerSchema);
