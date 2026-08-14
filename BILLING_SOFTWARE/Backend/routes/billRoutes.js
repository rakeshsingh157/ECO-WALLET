const express = require("express");
const router = express.Router();
const Bill = require("../models/Bill");
const Product = require("../models/Product");

// GET /api/bills — Fetch recent bills & dynamic sales summary
router.get("/", async (req, res) => {
  try {
    const bills = await Bill.find().sort({ createdAt: -1 }).limit(100);
    
    // Calculate today's sales based on current date
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const todayBills = bills.filter(b => new Date(b.createdAt) >= startOfToday);
    const todaySales = todayBills.reduce((sum, b) => sum + (Number(b.total_amount) || 0), 0);
    const totalSales = bills.reduce((sum, b) => sum + (Number(b.total_amount) || 0), 0);

    res.json({
      success: true,
      todaySales,
      todayBillCount: todayBills.length,
      totalSales,
      totalBillCount: bills.length,
      data: bills,
    });
  } catch (error) {
    res.status(500).json({ success: false, todaySales: 0, todayBillCount: 0, data: [], error: error.message });
  }
});

// POST /api/bills — Create new bill with stock auto-decrement
router.post("/", async (req, res) => {
  try {
    const { items, total_amount, payment_mode, customer_name, customer_phone, khata_customer_id, bill_id } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: "Bill must contain at least one item" });
    }

    const billId = bill_id || `BILL_${Date.now()}`;
    const newBill = new Bill({
      bill_id: billId,
      items: items.map(item => ({
        product_id: item.product_id || item.id || `p_${Date.now()}`,
        name: item.name || "Item",
        price: Number(item.price) || 0,
        quantity: Number(item.quantity) || 1,
      })),
      total_amount: Number(total_amount) || 0,
      payment_mode: payment_mode || "cash",
      customer_name: customer_name || "Counter Customer",
      customer_phone: customer_phone || null,
      khata_customer_id: khata_customer_id || null,
      status: payment_mode === "pending" ? "pending" : "completed",
    });

    await newBill.save();

    // Auto decrement stock for each product in the bill
    for (const item of newBill.items) {
      if (item.product_id) {
        try {
          await Product.findOneAndUpdate(
            { product_id: item.product_id },
            { $inc: { stock: -item.quantity } }
          );
        } catch (stockErr) {
          console.warn("Could not decrement stock for product:", item.product_id);
        }
      }
    }

    console.log(`✅ Bill created in MongoDB Atlas: #${newBill.bill_id} (₹${newBill.total_amount}, Mode: ${newBill.payment_mode})`);
    res.status(201).json({ success: true, data: newBill });
  } catch (error) {
    console.error("Bill create error:", error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// GET /api/bills/invoice/:bill_id — Dynamic HTML Invoice Download Route
router.get("/invoice/:bill_id", async (req, res) => {
  const billId = req.params.bill_id;
  try {
    const bill = await Bill.findOne({ bill_id: billId });
    const shopName = req.query.shop_name || "Dukaan Dost Store";
    const totalAmount = bill ? bill.total_amount : 0;
    const paymentMode = bill ? (bill.payment_mode || "CASH").toUpperCase() : "PAID";
    const dateStr = bill ? new Date(bill.createdAt).toLocaleString("en-IN") : new Date().toLocaleString("en-IN");
    
    let itemsHtml = "";
    if (bill && bill.items && bill.items.length > 0) {
      itemsHtml = bill.items.map(item => `
        <tr style="border-bottom: 1px solid #334155;">
          <td style="padding: 8px 0; color: #F8FAFC;">${item.name}</td>
          <td style="padding: 8px 0; text-align: center; color: #94A3B8;">${item.quantity}</td>
          <td style="padding: 8px 0; text-align: right; color: #F8FAFC;">₹${(item.price * item.quantity).toFixed(2)}</td>
        </tr>
      `).join("");
    } else {
      itemsHtml = `<tr><td colspan="3" style="padding: 10px 0; text-align: center; color: #94A3B8;">General Purchase</td></tr>`;
    }

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tax Invoice #${billId}</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0F172A; color: #F8FAFC; padding: 20px; margin: 0; }
          .card { max-width: 440px; margin: 20px auto; background: #1E293B; border-radius: 20px; padding: 24px; border: 1px solid #334155; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
          .header { text-align: center; border-bottom: 1px solid #334155; padding-bottom: 16px; margin-bottom: 16px; }
          .title { font-size: 22px; font-weight: bold; color: #FF8C75; margin-bottom: 4px; }
          .badge { background: #10B981; color: #fff; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: bold; display: inline-block; margin-top: 6px; letter-spacing: 0.5px; }
          .table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 13px; }
          .total-box { background: rgba(255, 140, 117, 0.1); border: 1px solid rgba(255, 140, 117, 0.3); border-radius: 12px; padding: 14px; margin: 16px 0; display: flex; justify-content: space-between; align-items: center; }
          .total-label { font-size: 14px; color: #94A3B8; }
          .total-val { font-size: 24px; font-weight: 800; color: #FF8C75; }
          .footer { text-align: center; margin-top: 20px; font-size: 11px; color: #64748B; line-height: 1.5; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="header">
            <div class="title">${shopName}</div>
            <div style="color: #94A3B8; font-size: 12px;">Tax Invoice #${billId}</div>
            <div class="badge">${paymentMode}</div>
            <div style="color: #64748B; font-size: 11px; margin-top: 6px;">${dateStr}</div>
          </div>
          <table class="table">
            <thead>
              <tr style="border-bottom: 1px solid #475569; color: #94A3B8;">
                <th style="text-align: left; padding-bottom: 6px;">Item</th>
                <th style="text-align: center; padding-bottom: 6px;">Qty</th>
                <th style="text-align: right; padding-bottom: 6px;">Total</th>
              </tr>
            </thead>
            <tbody>
              ${itemsHtml}
            </tbody>
          </table>
          <div class="total-box">
            <span class="total-label">Grand Total</span>
            <span class="total-val">₹${Number(totalAmount).toFixed(2)}</span>
          </div>
          <p style="text-align:center; font-size: 12px; color: #94A3B8; margin: 10px 0;">Thank you for shopping with us!</p>
          <div class="footer">Powered by Dukaan Dost Billing & POS</div>
        </div>
      </body>
      </html>
    `);
  } catch (error) {
    res.status(500).send("Error generating invoice: " + error.message);
  }
});

module.exports = router;
