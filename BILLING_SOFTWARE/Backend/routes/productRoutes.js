const express = require("express");
const router = express.Router();
const Product = require("../models/Product");

// GET /api/products — Fetch catalog from MongoDB Atlas
router.get("/", async (req, res) => {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    res.json({ success: true, count: products.length, data: products });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
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
      category: category || "General",
      unit: unit || "pcs",
      stock: Number(stock) || 0,
    });
    await newProduct.save();
    res.status(201).json({ success: true, data: newProduct });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
