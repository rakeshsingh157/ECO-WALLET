const mongoose = require("mongoose");

const BillItemSchema = new mongoose.Schema({
  product_id: { type: String, required: true },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true, default: 1 },
});

const BillSchema = new mongoose.Schema(
  {
    bill_id: { type: String, required: true, unique: true },
    items: [BillItemSchema],
    total_amount: { type: Number, required: true },
    payment_mode: {
      type: String,
      enum: ["cash", "upi", "ecoWallet", "pending"],
      required: true,
      default: "cash",
    },
    customer_name: { type: String },
    customer_phone: { type: String },
    khata_customer_id: { type: String },
    status: {
      type: String,
      enum: ["completed", "pending", "failed"],
      default: "completed",
    },
    payment_id: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Bill", BillSchema);
