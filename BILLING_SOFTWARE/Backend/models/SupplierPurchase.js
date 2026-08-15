const mongoose = require("mongoose");

const PurchaseItemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  quantity: { type: Number, required: true },
  cost_price: { type: Number, required: true },
  unit: { type: String, default: "pcs" },
});

const SupplierPurchaseSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    supplier_id: { type: String, required: true, index: true },
    purchase_id: { type: String, required: true, unique: true, index: true },
    invoice_number: { type: String, trim: true },
    items: [PurchaseItemSchema],
    total_amount: { type: Number, required: true, min: 0 },
    amount_paid: { type: Number, required: true, default: 0 },
    pending_amount: { type: Number, required: true, default: 0 },
    date: { type: Date, default: Date.now, index: true },
    notes: { type: String },
  },
  { timestamps: true }
);

SupplierPurchaseSchema.index({ merchant_id: 1, supplier_id: 1, date: -1 });

module.exports = mongoose.models.SupplierPurchase || mongoose.model("SupplierPurchase", SupplierPurchaseSchema);
