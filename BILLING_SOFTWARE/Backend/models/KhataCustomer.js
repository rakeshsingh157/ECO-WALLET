const mongoose = require("mongoose");

const KhataCustomerSchema = new mongoose.Schema(
  {
    customer_id: { type: String, required: true, unique: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    address: { type: String },
    aadhaar_number: { type: String },
    due_amount: { type: Number, required: true, default: 0 },
    last_transaction: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model("KhataCustomer", KhataCustomerSchema);
