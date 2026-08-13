const express = require("express");
const router = express.Router();
const Product = require("../models/Product");

// Seed initial default products if empty
const defaultProducts = [
  { product_id: "p1", name: "Chai Pack 250g", price: 120, category: "Beverages", unit: "pack", stock: 25, icon: "tea" },
  { product_id: "p2", name: "Full Cream Milk 1L", price: 66, category: "Beverages", unit: "pouch", stock: 40, icon: "milk" },
  { product_id: "p3", name: "Butter Cookie 200g", price: 50, category: "Snacks", unit: "pack", stock: 15, icon: "cookie" },
  { product_id: "p4", name: "Basmati Rice 1kg", price: 110, category: "Grains", unit: "kg", stock: 50, icon: "rice" },
  { product_id: "p5", name: "Wheat Atta 5kg", price: 210, category: "Grains", unit: "pack", stock: 12, icon: "grain" },
  { product_id: "p6", name: "Turmeric Powder 100g", price: 35, category: "Spices", unit: "pack", stock: 4, icon: "spice" },
  { product_id: "p7", name: "Bread Loaf 400g", price: 40, category: "Bakery", unit: "pcs", stock: 3, icon: "bread" },
  { product_id: "p8", name: "Sunflower Oil 1L", price: 145, category: "Oil & Ghee", unit: "bottle", stock: 2, icon: "oil" },
];

// GET /api/products — Fetch catalog
router.get("/", async (req, res) => {
  try {
    let products = await Product.find().sort({ createdAt: -1 });
    if (products.length === 0) {
      products = await Product.insertMany(defaultProducts);
    }
    res.json({ success: true, count: products.length, data: products });
  } catch (error) {
    res.json({ success: true, count: defaultProducts.length, data: defaultProducts });
  }
});

// POST /api/products — Add new catalog item
router.post("/", async (req, res) => {
  try {
    const { name, price, category, unit, stock } = req.body;
    const newProduct = new Product({
      product_id: `p_${Date.now()}`,
      name,
      price: Number(price),
      category: category || "Beverages",
      unit: unit || "pcs",
      stock: Number(stock) || 10,
    });
    await newProduct.save();
    res.status(201).json({ success: true, data: newProduct });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
