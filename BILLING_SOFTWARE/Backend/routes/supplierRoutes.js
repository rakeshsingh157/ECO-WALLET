const express = require("express");
const router = express.Router();
const Supplier = require("../models/Supplier");
const SupplierPurchase = require("../models/SupplierPurchase");

router.get("/", async (req, res) => {
  try {
    const { search, limit, page } = req.query;
    const merchantId = req.merchant_id || "mch_default";
    const query = { merchant_id: merchantId };

    if (search && search.trim().length > 0) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      query.$and = [
        {
          $or: [
            { name: { $regex: escaped, $options: "i" } },
            { company_name: { $regex: escaped, $options: "i" } },
            { phone: { $regex: escaped, $options: "i" } },
          ],
        },
      ];
    }

    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(500, Math.max(1, parseInt(limit) || 100));
    const skip = (pageNum - 1) * limitNum;

    const [suppliers, totalCount] = await Promise.all([
      Supplier.find(query)
        .sort({ pending_payment: -1, updatedAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Supplier.countDocuments(query),
    ]);

    const sanitized = suppliers.map((s) => ({
      id: s.supplier_id,
      supplier_id: s.supplier_id,
      name: s.name,
      company_name: s.company_name,
      companyName: s.company_name,
      phone: s.phone,
      gstin: s.gstin || "",
      address: s.address || "",
      pending_payment: s.pending_payment || 0,
      pendingPayment: s.pending_payment || 0,
      total_supplied: s.total_supplied || 0,
      orders_supplied: s.orders_supplied || 0,
      ordersSupplied: s.orders_supplied || 0,
    }));

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

router.get("/:id", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const supplier = await Supplier.findOne({
      merchant_id: merchantId,
      $or: [
        { supplier_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    }).lean();

    if (!supplier) {
      return res.status(404).json({ success: false, message: "Supplier not found" });
    }

    res.json({
      success: true,
      data: {
        id: supplier.supplier_id,
        supplier_id: supplier.supplier_id,
        name: supplier.name,
        company_name: supplier.company_name,
        companyName: supplier.company_name,
        phone: supplier.phone,
        gstin: supplier.gstin || "",
        address: supplier.address || "",
        pending_payment: supplier.pending_payment || 0,
        pendingPayment: supplier.pending_payment || 0,
        total_supplied: supplier.total_supplied || 0,
        orders_supplied: supplier.orders_supplied || 0,
        ordersSupplied: supplier.orders_supplied || 0,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const merchantId = req.merchant_id || req.body.merchant_id || "mch_default";
    const { name, company_name, companyName, phone, gstin, address, supplier_id } = req.body;

    const resolvedCompany = company_name || companyName;
    if (!name || !resolvedCompany) {
      return res.status(400).json({ success: false, message: "Contact name and company name are required" });
    }

    const supplierId = supplier_id || `sup_${Date.now()}`;
    const supplier = await Supplier.findOneAndUpdate(
      { merchant_id: merchantId, supplier_id: supplierId },
      {
        $set: {
          merchant_id: merchantId,
          supplier_id: supplierId,
          name: name.trim(),
          company_name: resolvedCompany.trim(),
          phone: phone ? phone.trim() : "",
          gstin: gstin ? gstin.trim() : "",
          address: address ? address.trim() : "",
        },
      },
      { upsert: true, new: true }
    );

    res.status(201).json({
      success: true,
      data: {
        id: supplier.supplier_id,
        supplier_id: supplier.supplier_id,
        name: supplier.name,
        company_name: supplier.company_name,
        companyName: supplier.company_name,
        phone: supplier.phone,
        gstin: supplier.gstin || "",
        pending_payment: supplier.pending_payment || 0,
        pendingPayment: supplier.pending_payment || 0,
        orders_supplied: supplier.orders_supplied || 0,
        ordersSupplied: supplier.orders_supplied || 0,
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post("/:id/pay", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const { amount } = req.body;
    const payAmount = Number(amount);

    if (!payAmount || payAmount <= 0) {
      return res.status(400).json({ success: false, message: "Valid payment amount is required" });
    }

    const supplier = await Supplier.findOne({
      merchant_id: merchantId,
      $or: [
        { supplier_id: req.params.id },
        ...(req.params.id.match(/^[0-9a-fA-F]{24}$/) ? [{ _id: req.params.id }] : []),
      ],
    });

    if (!supplier) {
      return res.status(404).json({ success: false, message: "Supplier not found" });
    }

    supplier.pending_payment = Math.max(0, supplier.pending_payment - payAmount);
    await supplier.save();

    res.json({
      success: true,
      message: "Supplier payment recorded",
      pending_payment: supplier.pending_payment,
      pendingPayment: supplier.pending_payment,
      data: supplier,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get("/:id/purchases", async (req, res) => {
  try {
    const merchantId = req.merchant_id || "mch_default";
    const purchases = await SupplierPurchase.find({ merchant_id: merchantId, supplier_id: req.params.id })
      .sort({ date: -1 })
      .limit(50)
      .lean();

    const sanitized = purchases.map((p) => ({
      id: p.purchase_id,
      invoice_number: p.invoice_number || p.purchase_id,
      total_amount: p.total_amount,
      amount_paid: p.amount_paid,
      pending_amount: p.pending_amount,
      items_count: (p.items || []).length,
      notes: p.notes || "Inward stock supply",
      date: p.date || p.createdAt,
    }));

    res.json({ success: true, count: sanitized.length, data: sanitized });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message, data: [] });
  }
});

module.exports = router;
