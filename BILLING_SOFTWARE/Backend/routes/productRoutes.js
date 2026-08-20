const express = require("express");
const router = express.Router();
const Product = require("../models/Product");

router.get("/", async (req, res) => {
  try {
    const { category, search, barcode, limit, page } = req.query;
    const merchantId = req.merchant_id || "mch_default";
    const query = { merchant_id: merchantId };

    if (category && category !== "All") {
      query.category = category;
    }

    if (barcode) {
      query.barcode = barcode;
    }

    if (search && search.trim().length > 0) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      query.$and = [
        {
          $or: [
            { name: { $regex: escaped, $options: "i" } },
            { barcode: { $regex: escaped, $options: "i" } },
            { category: { $regex: escaped, $options: "i" } },
          ],
        },
      ];
    }

    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(500, Math.max(1, parseInt(limit) || 100));
    const skip = (pageNum - 1) * limitNum;

    const [products, totalCount] = await Promise.all([
      Product.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Product.countDocuments(query),
    ]);

    const sanitized = products.map((p) => {
      if (p.stock < 0) p.stock = 0;
      return {
        ...p,
        id: p.product_id || p._id,
      };
    });

    res.json({
      success: true,
      count: sanitized.length,
      total: totalCount,
      page: pageNum,
      totalPages: Math.ceil(totalCount / limitNum),
      data: sanitized,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

router.get("/barcode/:code", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const product = await Product.findOne({
      merchant_id: merchantId,
      $or: [{ barcode: req.params.code }, { product_id: req.params.code }],
    }).lean();

    if (!product) {
      return res.status(404).json({ success: false, message: "Product with barcode not found" });
    }

    res.json({ success: true, data: { ...product, id: product.product_id || product._id } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/low-stock", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const products = await Product.find({
      merchant_id: merchantId,
      $expr: { $lte: ["$stock", { $ifNull: ["$min_stock_alert", 5] }] }
    })
      .sort({ stock: 1 })
      .limit(100)
      .lean();

    res.json({
      success: true,
      count: products.length,
      data: products.map((p) => ({ ...p, id: p.product_id || p._id })),
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const query = {
      merchant_id: merchantId,
      $or: [
        { product_id: req.params.id },
        { barcode: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    };
    const product = await Product.findOne(query).lean();
    if (!product) {
      return res.status(404).json({ success: false, message: "Product not found" });
    }
    res.json({ success: true, data: { ...product, id: product.product_id || product._id } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const merchantId = req.merchant_id || req.body.merchant_id || "mch_default";
    const { name, price, category, unit, stock, min_stock_alert, icon, barcode, product_id } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Product name is required" });
    }
    if (price === undefined || price === null || Number(price) < 0) {
      return res.status(400).json({ success: false, message: "Valid product price is required" });
    }

    const productId = product_id || `prod_${Date.now()}`;
    const productData = {
      merchant_id: merchantId,
      product_id: productId,
      name: name.trim(),
      price: Number(price),
      category: category || "Groceries",
      unit: unit || "pcs",
      stock: Number(stock) >= 0 ? Number(stock) : 0,
      min_stock_alert: min_stock_alert !== undefined ? Math.max(0, Number(min_stock_alert)) : 5,
      icon: icon || "box",
      barcode: barcode ? String(barcode).trim() : null,
    };

    const product = await Product.findOneAndUpdate(
      { merchant_id: merchantId, product_id: productId },
      { $set: productData },
      { upsert: true, new: true }
    );

    res.status(201).json({ success: true, data: { ...product.toObject(), id: product.product_id } });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.put("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const { name, price, category, unit, stock, min_stock_alert, icon, barcode } = req.body;
    const query = {
      merchant_id: merchantId,
      $or: [
        { product_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    };

    const updateFields = {};
    if (name) updateFields.name = name.trim();
    if (price !== undefined) updateFields.price = Number(price);
    if (category) updateFields.category = category;
    if (unit) updateFields.unit = unit;
    if (stock !== undefined) updateFields.stock = Math.max(0, Number(stock));
    if (min_stock_alert !== undefined) updateFields.min_stock_alert = Math.max(0, Number(min_stock_alert));
    if (icon) updateFields.icon = icon;
    if (barcode !== undefined) updateFields.barcode = barcode ? String(barcode).trim() : null;

    const updatedProduct = await Product.findOneAndUpdate(query, { $set: updateFields }, { new: true });
    if (!updatedProduct) {
      return res.status(404).json({ success: false, message: "Product not found" });
    }
    res.json({ success: true, data: { ...updatedProduct.toObject(), id: updatedProduct.product_id } });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const query = {
      merchant_id: merchantId,
      $or: [
        { product_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
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
