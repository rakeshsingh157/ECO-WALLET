const mongoose = require("mongoose");

const ExpenseSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    expense_id: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true, trim: true },
    amount: { type: Number, required: true, min: 0 },
    category: {
      type: String,
      enum: ["Utilities", "Rent", "Staff & Salary", "Transport", "Tea & Snacks", "Maintenance", "Inventory", "Other"],
      default: "Utilities",
      index: true,
    },
    payment_mode: { type: String, default: "Cash" },
    notes: { type: String, trim: true },
    date: { type: Date, default: Date.now, index: true },
  },
  { timestamps: true }
);

ExpenseSchema.index({ merchant_id: 1, date: -1 });
ExpenseSchema.index({ merchant_id: 1, category: 1 });

module.exports = mongoose.models.Expense || mongoose.model("Expense", ExpenseSchema);
