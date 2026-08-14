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

// GET /api/products/:id — Fetch single product
router.get("/:id", async (req, res) => {
  try {
    const product = await Product.findOne({
      $or: [{ product_id: req.params.id }, { _id: req.params.id.match(/^[0-9a-fA-F]{24}$/) ? req.params.id : null }],
    });
    if (!product) {
      return res.status(404).json({ success: false, message: "Product not found" });
    }
    res.json({ success: true, data: product });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/products — Add new catalog item with validation
router.post("/", async (req, res) => {
  try {
    const { name, price, category, unit, stock, icon, product_id } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Product name is required" });
    }
    if (price === undefined || price === null || Number(price) < 0) {
      return res.status(400).json({ success: false, message: "Valid product price is required" });
    }

    const productId = product_id || `p_${Date.now()}`;
    const newProduct = new Product({
      product_id: productId,
      name: name.trim(),
      price: Number(price),
      category: category || "General",
      unit: unit || "pcs",
      stock: Number(stock) !== undefined && !isNaN(Number(stock)) ? Number(stock) : 10,
      icon: icon || "box",
    });

    await newProduct.save();
    console.log(`✅ Product created in MongoDB Atlas: ${newProduct.name} (₹${newProduct.price})`);
    res.status(201).json({ success: true, data: newProduct });
  } catch (error) {
    console.error("Product create error:", error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// PUT /api/products/:id — Update catalog item
router.put("/:id", async (req, res) => {
  try {
    const { name, price, category, unit, stock, icon } = req.body;
    const query = {
      $or: [{ product_id: req.params.id }, { _id: req.params.id.match(/^[0-9a-fA-F]{24}$/) ? req.params.id : null }],
    };

    const updateFields = {};
    if (name) updateFields.name = name.trim();
    if (price !== undefined) updateFields.price = Number(price);
    if (category) updateFields.category = category;
    if (unit) updateFields.unit = unit;
    if (stock !== undefined) updateFields.stock = Number(stock);
    if (icon) updateFields.icon = icon;

    const updatedProduct = await Product.findOneAndUpdate(query, { $set: updateFields }, { new: true });
    if (!updatedProduct) {
      return res.status(404).json({ success: false, message: "Product not found" });
    }
    res.json({ success: true, data: updatedProduct });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// DELETE /api/products/:id — Delete catalog item
router.delete("/:id", async (req, res) => {
  try {
    const query = {
      $or: [{ product_id: req.params.id }, { _id: req.params.id.match(/^[0-9a-fA-F]{24}$/) ? req.params.id : null }],
    };
    const deleted = await Product.findOneAndDelete(query);
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Product not found" });
    }
    res.json({ success: true, message: "Product deleted successfully", data: deleted });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
