const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema(
  {
    product_id: { type: String, required: true, unique: true },
    name: { type: String, required: true, trim: true },
    price: { type: Number, required: true, min: 0 },
    category: { type: String, required: true, default: "Beverages" },
    unit: { type: String, required: true, default: "pcs" },
    stock: { type: Number, required: true, default: 10 },
    icon: { type: String, default: "box" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Product", ProductSchema);
