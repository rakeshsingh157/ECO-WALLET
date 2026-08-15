const mongoose = require("mongoose");

const SupplierSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    supplier_id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true, index: true },
    company_name: { type: String, required: true, trim: true, index: true },
    phone: { type: String, required: true, trim: true, index: true },
    gstin: { type: String, trim: true },
    address: { type: String, trim: true },
    pending_payment: { type: Number, required: true, default: 0, index: true },
    total_supplied: { type: Number, required: true, default: 0 },
    orders_supplied: { type: Number, required: true, default: 0 },
    last_order_date: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

SupplierSchema.index({ merchant_id: 1, pending_payment: -1 });
SupplierSchema.index({ merchant_id: 1, company_name: 1 });

module.exports = mongoose.models.Supplier || mongoose.model("Supplier", SupplierSchema);
