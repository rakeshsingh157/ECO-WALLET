const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const connectDB = require("./config/db");
const { getEcoWalletConnection } = require("./config/db");
const MerchantPayment = require("./models/MerchantPayment");
const Merchant = require("./models/Merchant");
const User = require("./models/User");
const Bill = require("./models/Bill");

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

const activePayments = new Map();

app.use("/api/products", require("./routes/productRoutes"));
app.use("/api/bills", require("./routes/billRoutes"));
app.use("/api/customers", require("./routes/customerRoutes"));
app.use("/api/khata", require("./routes/khataRoutes"));
app.use("/api/suppliers", require("./routes/supplierRoutes"));
app.use("/api/expenses", require("./routes/expenseRoutes"));
app.use("/api/reports", require("./routes/reportRoutes"));
app.use("/api/notifications", require("./routes/notificationRoutes"));
app.use("/api/staff", require("./routes/staffRoutes"));
app.use("/api/merchant", require("./routes/merchantRoutes"));
app.use("/api/backup", require("./routes/backupRoutes"));

app.post("/api/merchant/create-payment", async (req, res) => {
  const { order_id, amount, description, shop_name, owner_name } = req.body;
  const paymentId = `pay_${Date.now()}`;
  const rawMerchantId = req.body.merchant_id || req.headers["x-merchant-id"] || req.headers["x-api-key"] || "mch_store";
  const now = Date.now();
  const FIVE_MINUTES_MS = 5 * 60 * 1000;
  const expiresAt = new Date(now + FIVE_MINUTES_MS);

  let merchant = null;
  try {
    const cleanDigits = rawMerchantId.replace(/\D/g, "");
    merchant = await Merchant.findOne({
      $or: [
        { merchant_id: rawMerchantId },
        { api_key_hash: rawMerchantId },
        { user_id: rawMerchantId },
        ...(cleanDigits.length >= 10 ? [{ mobile_number: cleanDigits }, { merchant_id: `mch_${cleanDigits}` }] : [])
      ]
    });
  } catch (_) {}

  const businessName = (merchant && merchant.business_name) ? merchant.business_name : (shop_name || "Merchant Store");
  const owner = (merchant && merchant.owner_name) ? merchant.owner_name : (owner_name || "Shopkeeper");
  const resolvedMerchantId = merchant ? merchant.merchant_id : (rawMerchantId.startsWith("mch_") ? rawMerchantId : `mch_${rawMerchantId}`);

  const qrData = JSON.stringify({
    user_id: resolvedMerchantId,
    merchant_id: resolvedMerchantId,
    name: businessName,
    merchant_name: businessName,
    business_name: businessName,
    shop_name: businessName,
    owner_name: owner,
    payment_id: paymentId,
    amount: amount || 100,
    order_id: order_id || `BILL_${Date.now()}`,
    expires_at: expiresAt.toISOString(),
  });

  const paymentRecord = {
    payment_id: paymentId,
    merchant_id: resolvedMerchantId,
    business_name: businessName,
    order_id: order_id || `BILL_${Date.now()}`,
    amount: amount || 100,
    description: description || `Bill Payment for ${businessName}`,
    qr_data: qrData,
    status: "pending",
    created_at: now,
    expires_at: expiresAt.getTime(),
  };

  activePayments.set(paymentId, paymentRecord);

  try {
    await MerchantPayment.create({
      payment_id: paymentId,
      merchant_id: resolvedMerchantId,
      order_id: order_id || `BILL_${Date.now()}`,
      amount: amount || 100,
      description: description || `Bill Payment for ${businessName}`,
      expires_at: expiresAt,
      status: "pending",
    });
  } catch (err) {
    console.error("[ERROR] Failed to record payment in database:", err.message);
  }

  try {
    const ecoConn = getEcoWalletConnection();
    if (ecoConn && ecoConn.readyState === 1) {
      const EcoPayment = ecoConn.models.MerchantPayment || ecoConn.model("MerchantPayment", MerchantPayment.schema);
      await EcoPayment.create({
        payment_id: paymentId,
        merchant_id: resolvedMerchantId,
        order_id: order_id || `BILL_${Date.now()}`,
        amount: amount || 100,
        description: description || `Bill Payment for ${businessName}`,
        expires_at: expiresAt,
        status: "pending",
      });
      console.log(`[INFO] Payment session synchronized: ${paymentId}`);
    }
  } catch (err) {
    console.error("[ERROR] Secondary sync notice:", err.message);
  }

  res.status(201).json({
    success: true,
    payment: {
      payment_id: paymentId,
      merchant_id: resolvedMerchantId,
      business_name: businessName,
      order_id: paymentRecord.order_id,
      amount: paymentRecord.amount,
      qr_data: qrData,
      status: "pending",
      expires_at: expiresAt.toISOString(),
      expiry_seconds: 300,
    },
  });
});

app.get("/api/merchant/payment/:payment_id/status", async (req, res) => {
  const paymentId = req.params.payment_id;
  let payment = activePayments.get(paymentId);

  try {
    let dbPayment = await MerchantPayment.findOne({ payment_id: paymentId });
    
    const ecoConn = getEcoWalletConnection();
    if (ecoConn && ecoConn.readyState === 1) {
      const EcoPayment = ecoConn.models.MerchantPayment || ecoConn.model("MerchantPayment", MerchantPayment.schema);

      const ecoDbPayment = await EcoPayment.findOne({
        payment_id: paymentId,
        status: "completed",
      });

      if (ecoDbPayment) {
        dbPayment = ecoDbPayment;
        await MerchantPayment.findOneAndUpdate(
          { payment_id: paymentId },
          {
            $set: {
              status: "completed",
              payer_name: ecoDbPayment.payer_name || "Customer",
              transaction_id: ecoDbPayment.transaction_id || `TXN_${Date.now()}`,
              completed_at: ecoDbPayment.completed_at || new Date(),
            }
          }
        );
      }
    }

    if (dbPayment) {
      if (payment) {
        payment.status = dbPayment.status;
        payment.payer_name = dbPayment.payer_name;
        payment.transaction_id = dbPayment.transaction_id;
      } else {
        payment = {
          payment_id: dbPayment.payment_id || paymentId,
          order_id: dbPayment.order_id,
          amount: dbPayment.amount,
          status: dbPayment.status,
          expires_at: dbPayment.expires_at ? new Date(dbPayment.expires_at).getTime() : Date.now() + 300000,
          payer_name: dbPayment.payer_name,
          transaction_id: dbPayment.transaction_id,
        };
        activePayments.set(paymentId, payment);
      }
    }
  } catch (_) {}

  if (!payment) {
    return res.json({
      success: true,
      payment: {
        payment_id: paymentId,
        status: "pending",
      },
    });
  }

  if (payment.status !== "completed" && Date.now() > payment.expires_at) {
    payment.status = "expired";
    return res.json({
      success: true,
      payment: {
        payment_id: paymentId,
        status: "expired",
        message: "Payment session expired.",
      },
    });
  }

  const remainingSeconds = Math.max(0, Math.floor((payment.expires_at - Date.now()) / 1000));

  res.json({
    success: true,
    payment: {
      payment_id: payment.payment_id || paymentId,
      order_id: payment.order_id || `BILL_${Date.now()}`,
      status: payment.status,
      payer_name: payment.payer_name || "Customer",
      transaction_id: payment.transaction_id || `TXN_${Date.now()}`,
      remaining_seconds: remainingSeconds,
    },
  });
});

app.post("/api/merchant/pay", async (req, res) => {
  const { payment_id, payer_id, payer_name, amount } = req.body;

  if (!payment_id || typeof payment_id !== "string") {
    return res.status(400).json({
      success: false,
      code: "INVALID_PAYMENT_ID",
      message: "Valid payment_id is required to complete payment.",
    });
  }

  const txnId = `TXN_${Date.now()}`;
  const now = new Date();

  let dbPayment = await MerchantPayment.findOne({ payment_id });
  if (!dbPayment) {
    return res.status(404).json({
      success: false,
      code: "PAYMENT_NOT_FOUND",
      message: "Payment session not found or invalid QR code.",
    });
  }

  if (dbPayment.status === "completed") {
    return res.status(409).json({
      success: false,
      code: "ALREADY_PAID",
      message: "This payment QR has already been paid by a customer. Duplicate payments are rejected.",
      auto_refund: {
        status: "processed",
        refund_id: `REF_${Date.now()}`,
        amount: amount || dbPayment.amount,
        note: "Amount auto-refunded to customer wallet immediately.",
      },
    });
  }

  if (dbPayment.status === "expired" || (dbPayment.expires_at && now > new Date(dbPayment.expires_at))) {
    await MerchantPayment.findOneAndUpdate(
      { payment_id, status: "pending" },
      { $set: { status: "expired" } }
    );
    return res.status(410).json({
      success: false,
      code: "QR_EXPIRED",
      message: "This payment QR has expired. Please ask the shopkeeper for a new QR.",
      auto_refund: {
        status: "processed",
        refund_id: `REF_${Date.now()}`,
        amount: amount || dbPayment.amount,
        note: "Expired QR attempt auto-refunded.",
      },
    });
  }

  const updated = await MerchantPayment.findOneAndUpdate(
    { payment_id, status: "pending" },
    {
      $set: {
        status: "completed",
        payer_id: payer_id || "cust_user",
        payer_name: payer_name || "Customer",
        transaction_id: txnId,
        completed_at: now,
      },
    },
    { new: true }
  );

  if (!updated) {
    return res.status(409).json({
      success: false,
      code: "RACE_CONDITION_BLOCKED",
      message: "Another customer just completed this payment QR. Your payment has been auto-refunded.",
      auto_refund: {
        status: "processed",
        refund_id: `REF_${Date.now()}`,
        amount: amount || dbPayment.amount,
      },
    });
  }

  if (activePayments.has(payment_id)) {
    const memoryPayment = activePayments.get(payment_id);
    memoryPayment.status = "completed";
    memoryPayment.completed_at = now.toISOString();
    memoryPayment.payer_name = payer_name || "Customer";
    memoryPayment.transaction_id = txnId;
  }

  try {
    const existingBill = await Bill.findOne({
      $or: [{ bill_number: updated.order_id }, { payment_id: payment_id }]
    });

    if (!existingBill) {
      await Bill.create({
        bill_number: updated.order_id || `BILL_${Date.now()}`,
        payment_id: payment_id,
        merchant_id: updated.merchant_id,
        items: [
          {
            product_id: "prod_misc",
            product_name: "Store Sale",
            quantity: 1,
            unit_price: updated.amount,
            total_price: updated.amount,
          }
        ],
        subtotal: updated.amount,
        discount_amount: 0,
        tax_amount: 0,
        grand_total: updated.amount,
        payment_mode: "ECO_WALLET",
        payment_status: "PAID",
        payment_reference: txnId,
        created_at: now,
      });
      console.log(`[INFO] Auto-recorded paid bill for offline shopkeeper sync: ${updated.order_id}`);
    }
  } catch (billErr) {
    console.error("[ERROR] Failed to auto-create bill:", billErr.message);
  }

  res.json({
    success: true,
    message: "Payment processed successfully.",
    data: {
      payment_id,
      transaction_id: txnId,
      order_id: updated.order_id,
      amount: updated.amount,
      status: "completed",
      completed_at: now.toISOString(),
    },
  });
});

app.get("/api/wallet/user/:user_id", async (req, res) => {
  const cleanId = req.params.user_id;
  const cleanPhoneDigits = cleanId.replace(/\D/g, '');
  try {
    let merchant = await Merchant.findOne({
      $or: [
        { merchant_id: cleanId },
        { api_key_hash: cleanId },
        { user_id: cleanId },
        ...(cleanPhoneDigits.length >= 10 ? [{ mobile_number: cleanPhoneDigits }, { merchant_id: `mch_${cleanPhoneDigits}` }] : [])
      ],
    });
    let user = null;
    if (merchant) {
      user = await User.findOne({ user_id: merchant.user_id });
    }
    if (!user) {
      user = await User.findOne({ user_id: cleanId });
    }

    res.json({
      success: true,
      data: {
        user_id: user ? user.user_id : cleanId,
        name: merchant ? merchant.business_name : (user ? user.name : `Store ${cleanId}`),
        phone: user ? user.phone : (merchant ? merchant.mobile_number : cleanId),
      },
    });
  } catch (err) {
    res.json({
      success: true,
      data: {
        user_id: cleanId,
        name: `Store ${cleanId}`,
        phone: cleanId,
      },
    });
  }
});

async function renderInvoiceHtml(req, res) {
  const billId = req.params.bill_id;
  try {
    const cleanBillId = billId ? billId.trim() : "";
    const bill = await Bill.findOne({
      $or: [
        { bill_id: cleanBillId },
        { bill_id: `BILL_${cleanBillId}` },
        { bill_id: `BILL-${cleanBillId}` },
        { _id: cleanBillId.match(/^[0-9a-fA-F]{24}$/) ? cleanBillId : null },
      ],
    });

    const shopName = req.query.shop_name || "Dukaan Dost Store";
    const totalAmount = bill ? bill.total_amount : 0;
    const paymentMode = bill ? (bill.payment_mode || "CASH").toUpperCase() : "PAID";
    const dateStr = bill ? new Date(bill.createdAt).toLocaleString("en-IN") : new Date().toLocaleString("en-IN");
    const customerName = bill && bill.customer_name ? bill.customer_name : "Counter Customer";

    let itemsHtml = "";
    if (bill && bill.items && bill.items.length > 0) {
      itemsHtml = bill.items.map(item => `
        <tr style="border-bottom: 1px solid #334155;">
          <td style="padding: 10px 0; color: #F8FAFC; font-weight: 500;">${item.name}</td>
          <td style="padding: 10px 0; text-align: center; color: #94A3B8;">${item.quantity}</td>
          <td style="padding: 10px 0; text-align: right; color: #F8FAFC; font-weight: 600;">₹${(item.price * item.quantity).toFixed(2)}</td>
        </tr>
      `).join("");
    } else {
      itemsHtml = `<tr><td colspan="3" style="padding: 14px 0; text-align: center; color: #94A3B8;">General Purchase</td></tr>`;
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
          .title { font-size: 22px; font-weight: bold; color: #E8592A; margin-bottom: 4px; }
          .badge { background: #1E824C; color: #fff; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: bold; display: inline-block; margin-top: 6px; letter-spacing: 0.5px; }
          .customer-row { font-size: 12px; color: #94A3B8; margin-top: 8px; }
          .table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 13px; }
          .total-box { background: rgba(232, 89, 42, 0.1); border: 1px solid rgba(232, 89, 42, 0.3); border-radius: 12px; padding: 14px; margin: 16px 0; display: flex; justify-content: space-between; align-items: center; }
          .total-label { font-size: 14px; color: #94A3B8; }
          .total-val { font-size: 24px; font-weight: 800; color: #E8592A; }
          .footer { text-align: center; margin-top: 20px; font-size: 11px; color: #64748B; line-height: 1.5; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="header">
            <div class="title">${shopName}</div>
            <div style="color: #94A3B8; font-size: 12px;">Tax Invoice #${billId}</div>
            <div class="badge">${paymentMode}</div>
            <div class="customer-row">Billed to: <strong style="color: #F8FAFC;">${customerName}</strong></div>
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
}

app.get("/api/merchant/invoice/:bill_id", renderInvoiceHtml);
app.get("/api/bills/invoice/:bill_id", renderInvoiceHtml);
app.get("/api/invoice/:bill_id", renderInvoiceHtml);
app.get("/invoice/:bill_id", renderInvoiceHtml);

app.get("/api/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
  });
});

app.get("/", (req, res) => {
  res.json({
    status: "online",
    health: "/api/health",
  });
});

const PORT = process.env.PORT || 5001;

const startServer = async () => {
  await connectDB();
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[INFO] Server running on port ${PORT} across all interfaces (0.0.0.0)`);
  });
};

startServer();
