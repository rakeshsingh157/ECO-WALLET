const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema(
  {
    merchant_id: { type: String, default: "mch_default", index: true },
    product_id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true, index: true },
    price: { type: Number, required: true, min: 0 },
    category: { type: String, required: true, default: "Groceries", index: true },
    unit: { type: String, required: true, default: "pcs" },
    stock: { type: Number, required: true, default: 0, index: true },
    icon: { type: String, default: "box" },
    barcode: { type: String, trim: true, index: true },
  },
  { timestamps: true }
);

ProductSchema.index({ merchant_id: 1, category: 1 });
ProductSchema.index({ merchant_id: 1, stock: 1 });
ProductSchema.index({ merchant_id: 1, barcode: 1 });
ProductSchema.index({ merchant_id: 1, name: "text" });

module.exports = mongoose.models.Product || mongoose.model("Product", ProductSchema);
