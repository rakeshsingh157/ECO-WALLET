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

app.post("/api/merchant/refund", async (req, res) => {
  const { payment_id, order_id, amount, reason } = req.body;
  if (!payment_id && !order_id) {
    return res.status(400).json({ success: false, message: "payment_id or order_id is required for refund." });
  }

  try {
    const query = payment_id ? { payment_id } : { order_id };
    const payment = await MerchantPayment.findOne(query);
    if (!payment) {
      return res.status(404).json({ success: false, message: "Payment session not found." });
    }

    if (payment.status !== "completed" && payment.status !== "partially_refunded") {
      return res.status(400).json({ success: false, message: `Cannot refund payment with status '${payment.status}'.` });
    }

    const currentRefunded = Number(payment.refunded_amount || 0);
    const remainingRefundable = Math.max(0, payment.amount - currentRefunded);
    if (remainingRefundable <= 0) {
      return res.status(400).json({ success: false, message: "This payment is already fully refunded." });
    }

    const refundAmount = amount ? Math.min(Number(amount), remainingRefundable) : remainingRefundable;
    const refundId = `REF_${Date.now()}`;
    const newTotalRefunded = currentRefunded + refundAmount;
    const newStatus = newTotalRefunded >= payment.amount ? "refunded" : "partially_refunded";
    const newRefundStatus = newTotalRefunded >= payment.amount ? "full" : "partial";

    await MerchantPayment.findOneAndUpdate(
      { payment_id: payment.payment_id },
      {
        $set: {
          status: newStatus,
          refund_status: newRefundStatus,
          refunded_amount: newTotalRefunded,
        },
        $push: {
          refund_history: {
            refund_id: refundId,
            amount: refundAmount,
            reason: reason || "Merchant initiated refund",
            created_at: new Date(),
          }
        }
      }
    );

    await Bill.findOneAndUpdate(
      { $or: [{ payment_id: payment.payment_id }, { bill_number: payment.order_id }] },
      { $set: { payment_status: newStatus === "refunded" ? "REFUNDED" : "PARTIALLY_REFUNDED" } }
    );

    res.json({
      success: true,
      message: `Refund of ₹${refundAmount} processed successfully.`,
      data: {
        refund_id: refundId,
        payment_id: payment.payment_id,
        order_id: payment.order_id,
        refunded_amount: refundAmount,
        total_refunded: newTotalRefunded,
        status: newStatus,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || "Failed to process refund." });
  }
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

    let merchant = null;
    if (bill && bill.merchant_id) {
      merchant = await Merchant.findOne({
        $or: [{ merchant_id: bill.merchant_id }, { user_id: bill.merchant_id }]
      });
    }

    const shopName = req.query.shop_name || (merchant ? merchant.business_name : "Dukaan Dost Retail Store");
    const shopPhone = merchant ? (merchant.mobile_number || merchant.phone) : "+91 98765 43210";
    const shopAddress = merchant && merchant.address ? merchant.address : "Market Area, Main Road, India";
    const shopGstin = merchant && merchant.gstin ? merchant.gstin : "";
    const totalAmount = bill ? bill.total_amount : 0;
    const refundedAmount = bill && bill.refunded_amount ? bill.refunded_amount : 0;
    const netAmount = Math.max(0, totalAmount - refundedAmount);
    const paymentMode = bill ? (bill.payment_mode || "CASH").toUpperCase() : "PAID";
    const dateStr = bill ? new Date(bill.createdAt).toLocaleString("en-IN") : new Date().toLocaleString("en-IN");
    const customerName = bill && bill.customer_name ? bill.customer_name : "Counter Customer";
    const customerPhone = bill && bill.customer_phone ? bill.customer_phone : "";

    let itemsHtml = "";
    if (bill && bill.items && bill.items.length > 0) {
      itemsHtml = bill.items.map((item, idx) => {
        let displayQty = `${item.quantity}`;
        const unitStr = (item.unit || "pcs").toLowerCase();
        if (unitStr === "kg" && item.quantity < 1.0) {
          displayQty = `${Math.round(item.quantity * 1000)} g`;
        } else if ((unitStr === "ltr" || unitStr === "l") && item.quantity < 1.0) {
          displayQty = `${Math.round(item.quantity * 1000)} ml`;
        } else {
          displayQty = `${item.quantity} ${item.unit || "pcs"}`;
        }
        return `
        <tr style="border-bottom: 1px solid #334155;">
          <td style="padding: 10px 4px; color: #94A3B8; font-size: 11px;">${idx + 1}</td>
          <td style="padding: 10px 8px; color: #F8FAFC; font-weight: 600;">${item.name}</td>
          <td style="padding: 10px 8px; text-align: center; color: #CBD5E1; font-weight: 500;">${displayQty}</td>
          <td style="padding: 10px 8px; text-align: right; color: #94A3B8;">₹${Number(item.price).toFixed(2)}</td>
          <td style="padding: 10px 4px; text-align: right; color: #F8FAFC; font-weight: 700;">₹${(item.price * item.quantity).toFixed(2)}</td>
        </tr>
      `;
      }).join("");
    } else {
      itemsHtml = `<tr><td colspan="5" style="padding: 14px 0; text-align: center; color: #94A3B8;">General Store Purchase</td></tr>`;
    }

    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tax Invoice #${cleanBillId} - ${shopName}</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
        <style>
          * { box-sizing: border-box; }
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #0A0E1A; color: #F8FAFC; padding: 16px; margin: 0; display: flex; flex-direction: column; align-items: center; }
          .container { max-width: 520px; width: 100%; margin: 10px auto; }
          .actions { display: flex; gap: 10px; margin-bottom: 16px; width: 100%; max-width: 520px; }
          .btn { flex: 1; padding: 14px; border-radius: 12px; font-weight: 700; font-size: 14px; border: none; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; text-decoration: none; transition: 0.2s; }
          .btn-download { background: #E8592A; color: #FFFFFF; box-shadow: 0 4px 14px rgba(232, 89, 42, 0.4); }
          .btn-download:hover { background: #D0481B; }
          .btn-print { background: #1E293B; color: #F8FAFC; border: 1px solid #334155; }
          .invoice-card { background: #111827; border-radius: 20px; padding: 24px; border: 1px solid #1F2937; box-shadow: 0 20px 40px rgba(0,0,0,0.6); }
          .header { border-bottom: 1px solid #1F2937; padding-bottom: 16px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: flex-start; }
          .shop-title { font-size: 20px; font-weight: 800; color: #E8592A; margin: 0 0 4px 0; }
          .shop-sub { font-size: 11px; color: #9CA3AF; line-height: 1.4; }
          .badge { background: #065F46; color: #6EE7B7; padding: 4px 10px; border-radius: 8px; font-size: 11px; font-weight: 700; display: inline-block; }
          .badge-return { background: #7F1D1D; color: #FCA5A5; }
          .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 16px; font-size: 12px; }
          .info-label { color: #9CA3AF; font-size: 10px; text-transform: uppercase; font-weight: 700; letter-spacing: 0.5px; margin-bottom: 2px; }
          .info-val { color: #F9FAFB; font-weight: 600; }
          .table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 12px; }
          .table th { color: #9CA3AF; font-size: 10px; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #374151; padding: 8px 4px; }
          .summary-box { background: #1F2937; border-radius: 12px; padding: 14px; margin-top: 16px; border: 1px solid #374151; }
          .summary-row { display: flex; justify-content: space-between; font-size: 12px; color: #9CA3AF; margin-bottom: 6px; }
          .summary-total { display: flex; justify-content: space-between; font-size: 18px; font-weight: 800; color: #E8592A; margin-top: 8px; padding-top: 8px; border-top: 1px solid #374151; }
          .footer { text-align: center; margin-top: 20px; font-size: 11px; color: #6B7280; line-height: 1.5; border-top: 1px solid #1F2937; padding-top: 14px; }
          @media print {
            body { background: #FFFFFF; color: #000000; padding: 0; }
            .actions { display: none !important; }
            .invoice-card { background: #FFFFFF; color: #000000; border: none; box-shadow: none; padding: 0; }
            .shop-title { color: #000000; }
            .info-val, .table td { color: #000000 !important; }
            .summary-box { background: #F3F4F6; border: 1px solid #E5E7EB; }
            .summary-total { color: #000000 !important; }
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="actions">
            <button class="btn btn-download" onclick="downloadPdf()">
              <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
              Download PDF Invoice
            </button>
            <button class="btn btn-print" onclick="window.print()">
              <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
              Print
            </button>
          </div>

          <div class="invoice-card" id="invoice-capture">
            <div class="header">
              <div>
                <h1 class="shop-title">${shopName}</h1>
                <div class="shop-sub">${shopAddress}</div>
                <div class="shop-sub">Ph: ${shopPhone}${shopGstin ? ` • GSTIN: ${shopGstin}` : ""}</div>
              </div>
              <div style="text-align: right;">
                <div class="badge ${refundedAmount > 0 ? 'badge-return' : ''}">
                  ${refundedAmount >= totalAmount ? 'FULL RETURN' : (refundedAmount > 0 ? 'PARTIAL RETURN' : paymentMode)}
                </div>
                <div style="font-size: 11px; color: #9CA3AF; margin-top: 6px; font-weight: 700;">#${cleanBillId}</div>
              </div>
            </div>

            <div class="info-grid">
              <div>
                <div class="info-label">Customer</div>
                <div class="info-val">${customerName}${customerPhone ? ` (${customerPhone})` : ""}</div>
              </div>
              <div style="text-align: right;">
                <div class="info-label">Date & Time</div>
                <div class="info-val">${dateStr}</div>
              </div>
            </div>

            <table class="table">
              <thead>
                <tr>
                  <th style="text-align: left; width: 24px;">#</th>
                  <th style="text-align: left;">Item</th>
                  <th style="text-align: center;">Qty/Wt</th>
                  <th style="text-align: right;">Rate</th>
                  <th style="text-align: right;">Total</th>
                </tr>
              </thead>
              <tbody>
                ${itemsHtml}
              </tbody>
            </table>

            <div class="summary-box">
              <div class="summary-row">
                <span>Subtotal</span>
                <span>₹${Number(totalAmount).toFixed(2)}</span>
              </div>
              <div class="summary-row">
                <span>GST / Taxes</span>
                <span>₹0.00 (Inclusive)</span>
              </div>
              ${refundedAmount > 0 ? `
              <div class="summary-row" style="color: #F87171; font-weight: 700;">
                <span>Total Refunded / Returned</span>
                <span>-₹${Number(refundedAmount).toFixed(2)}</span>
              </div>
              ` : ''}
              <div class="summary-total">
                <span>GRAND TOTAL</span>
                <span>₹${Number(netAmount).toFixed(2)}</span>
              </div>
            </div>

            <div class="footer">
              <p style="margin: 0 0 4px 0; color: #9CA3AF; font-weight: 600;">Thank you for shopping with us!</p>
              <div>Powered by Dukaan Dost Smart Billing</div>
            </div>
          </div>
        </div>

        <script>
          function downloadPdf() {
            const element = document.getElementById('invoice-capture');
            const opt = {
              margin: 10,
              filename: 'Invoice_${cleanBillId}.pdf',
              image: { type: 'jpeg', quality: 0.98 },
              html2canvas: { scale: 2, useCORS: true },
              jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
            };
            html2pdf().set(opt).from(element).save();
          }
        </script>
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
