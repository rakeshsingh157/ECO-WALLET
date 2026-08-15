const mongoose = require("mongoose");

const KhataLedgerSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    customer_id: { type: String, required: true, index: true },
    type: { type: String, enum: ["credit", "payment"], required: true, index: true },
    amount: { type: Number, required: true, min: 0 },
    bill_id: { type: String, index: true },
    note: { type: String, trim: true },
    date: { type: Date, default: Date.now, index: true },
  },
  { timestamps: true }
);

KhataLedgerSchema.index({ merchant_id: 1, customer_id: 1, date: -1 });

module.exports = mongoose.models.KhataLedger || mongoose.model("KhataLedger", KhataLedgerSchema);
