const express = require("express");
const router = express.Router();
const Merchant = require("../models/Merchant");
const MerchantPayment = require("../models/MerchantPayment");
const User = require("../models/User");
const Bank = require("../models/Bank");
const Transaction = require("../models/Transaction");
const { protect } = require("../middleware/auth");
const { generateTransactionId } = require("../utils/idGenerator");

router.post("/register", protect, async (req, res) => {
  try {
    const { business_name, owner_name, mobile_number, email, address, gstin } = req.body;
    if (!business_name || !owner_name || !mobile_number) {
      return res.status(400).json({ success: false, message: "Business name, owner name and mobile number are required" });
    }

    const existing = await Merchant.findOne({ user_id: req.user.user_id });
    if (existing) {
      return res.status(400).json({ success: false, message: "Merchant already registered" });
    }

    const merchantId = "MCH_" + Math.random().toString(36).substring(2, 9).toUpperCase();
    const apiKey = "dd_sec_" + Buffer.from(merchantId + Date.now()).toString("base64url");

    const merchant = await Merchant.create({
      merchant_id: merchantId,
      user_id: req.user.user_id,
      business_name,
      owner_name,
      mobile_number,
      email: email || req.user.email,
      address: address || "",
      gstin: gstin || "",
      api_key: apiKey,
    });

    res.status(201).json({
      success: true,
      message: "Merchant registered successfully",
      data: merchant,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/profile", protect, async (req, res) => {
  try {
    const merchant = await Merchant.findOne({ user_id: req.user.user_id });
    if (!merchant) {
      return res.status(404).json({ success: false, message: "Merchant profile not found" });
    }
    res.json({ success: true, data: merchant });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post("/pay", async (req, res) => {
  try {
    const { merchant_id, user_id, amount, order_id } = req.body;
    if (!merchant_id || !user_id || !amount || amount <= 0) {
      return res.status(400).json({ success: false, message: "Invalid payment details" });
    }

    const merchant = await Merchant.findOne({
      $or: [{ merchant_id }, { user_id: merchant_id }]
    });
    if (!merchant) {
      return res.status(404).json({ success: false, message: "Merchant not found" });
    }

    const payer = await User.findOne({ user_id });
    if (!payer) {
      return res.status(404).json({ success: false, message: "Payer user not found" });
    }

    if (payer.balance < amount) {
      return res.status(400).json({ success: false, message: "Insufficient wallet balance" });
    }

    const merchantUser = await User.findOne({ user_id: merchant.user_id });
    if (!merchantUser) {
      return res.status(404).json({ success: false, message: "Merchant wallet user not found" });
    }

    payer.balance -= amount;
    await payer.save();

    merchantUser.balance += amount;
    await merchantUser.save();

    merchant.total_collected = (merchant.total_collected || 0) + amount;
    merchant.total_orders = (merchant.total_orders || 0) + 1;
    await merchant.save();

    const paymentId = "PAY_" + Math.random().toString(36).substring(2, 9).toUpperCase();
    const payment = await MerchantPayment.create({
      payment_id: paymentId,
      order_id: order_id || "ORD_" + Date.now(),
      merchant_id: merchant.merchant_id,
      payer_id: payer.user_id,
      payer_name: payer.name || "Customer",
      amount: amount,
      status: "completed",
      completed_at: new Date(),
    });

    const txId = generateTransactionId();
    await Transaction.create({
      transaction_id: txId,
      sender_id: payer.user_id,
      receiver_id: merchantUser.user_id,
      amount: amount,
      type: "transfer",
      status: "completed",
      description: `Payment for Order #${order_id || paymentId} at ${merchant.business_name}`,
    });

    res.json({
      success: true,
      message: "Payment completed successfully",
      data: {
        payment_id: payment.payment_id,
        order_id: payment.order_id,
        amount: payment.amount,
        merchant_name: merchant.business_name,
        timestamp: payment.completed_at,
        transaction_id: txId,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

const renderInvoice = async (req, res) => {
  try {
    const { bill_id } = req.params;
    const cleanBillId = bill_id ? bill_id.trim() : "";
    const payment = await MerchantPayment.findOne({
      $or: [
        { payment_id: cleanBillId },
        { order_id: cleanBillId },
        { payment_id: `BILL_${cleanBillId}` },
        { order_id: `BILL_${cleanBillId}` },
      ]
    }).lean();

    let merchant = null;
    if (payment && payment.merchant_id) {
      merchant = await Merchant.findOne({
        $or: [{ merchant_id: payment.merchant_id }, { user_id: payment.merchant_id }]
      }).lean();
    }

    const shopName = req.query.shop_name || (payment && payment.shop_name) || (merchant ? merchant.business_name : "Dukaan Dost Retail Store");
    const ownerName = req.query.owner_name || (payment && payment.owner_name) || (merchant ? merchant.owner_name : "");
    const shopPhone = req.query.phone || req.query.shop_phone || (payment && payment.shop_phone) || (merchant ? merchant.mobile_number : "+91 98765 43210");
    const shopAddress = req.query.address || req.query.shop_address || (payment && payment.shop_address) || (merchant && merchant.address ? merchant.address : "Market Area, Main Road, India");
    const shopGstin = req.query.gstin || req.query.shop_gstin || (payment && payment.shop_gstin) || (merchant && merchant.gstin ? merchant.gstin : "");
    const amount = payment ? payment.amount : 0;
    const orderId = payment ? payment.order_id : cleanBillId;
    const payerName = payment ? (payment.payer_name || "Counter Customer") : "Valued Customer";
    const dateStr = payment && payment.completed_at ? new Date(payment.completed_at).toLocaleString("en-IN") : new Date().toLocaleString("en-IN");
    const statusStr = payment ? payment.status.toUpperCase() : "COMPLETED";

    const htmlContent = `
<!DOCTYPE html>
<html lang="en" style="background-color: #FFFFFF !important; color-scheme: light only !important;">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light only">
  <meta name="supported-color-schemes" content="light">
  <title>Tax Invoice - ${orderId}</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
  <style>
    :root {
      color-scheme: light only !important;
    }
    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
      background-color: #FFFFFF !important;
      background: #FFFFFF !important;
      color: #000000 !important;
      -webkit-text-fill-color: #000000 !important;
    }
    html, body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #FFFFFF !important;
      background: #FFFFFF !important;
      color: #000000 !important;
      -webkit-text-fill-color: #000000 !important;
      margin: 0;
      padding: 16px;
      display: flex;
      flex-direction: column;
      align-items: center;
      color-scheme: light only !important;
    }
    @media (prefers-color-scheme: dark) {
      * {
        background-color: #FFFFFF !important;
        background: #FFFFFF !important;
        color: #000000 !important;
        -webkit-text-fill-color: #000000 !important;
      }
      html, body, .container, .card, #invoice-capture {
        background-color: #FFFFFF !important;
        background: #FFFFFF !important;
        color: #000000 !important;
        -webkit-text-fill-color: #000000 !important;
      }
    }
    .container { max-width: 560px; width: 100%; margin: 10px auto; }
    .actions { display: flex; gap: 10px; margin-bottom: 16px; width: 100%; max-width: 560px; }
    .btn { flex: 1; padding: 14px; border-radius: 10px; font-weight: 700; font-size: 14px; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; text-decoration: none; }
    .btn-download { background: #000000; color: #FFFFFF !important; -webkit-text-fill-color: #FFFFFF !important; border: 1px solid #000000; }
    .btn-print { background: #FFFFFF; color: #000000 !important; -webkit-text-fill-color: #000000 !important; border: 1px solid #000000; }
    .card { background-color: #FFFFFF !important; color: #000000 !important; -webkit-text-fill-color: #000000 !important; border: 2px solid #000000; border-radius: 12px; padding: 24px; width: 100%; box-shadow: 0 4px 15px rgba(0,0,0,0.06); }
    .tax-header { text-align: center; border-bottom: 2px solid #000000; padding-bottom: 12px; margin-bottom: 16px; }
    .tax-title { font-size: 12px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; color: #000000 !important; -webkit-text-fill-color: #000000 !important; margin-bottom: 4px; }
    .title { font-size: 24px; font-weight: 900; color: #000000 !important; -webkit-text-fill-color: #000000 !important; margin: 0 0 4px 0; }
    .info-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; border: 1.5px solid #000000; }
    .info-table td { padding: 8px 10px; font-size: 12px; border: 1px solid #000000; color: #000000 !important; -webkit-text-fill-color: #000000 !important; background-color: #FFFFFF !important; }
    .total-box { border: 2px solid #000000; border-radius: 8px; padding: 14px; display: flex; justify-content: space-between; align-items: center; margin: 16px 0; background-color: #FFFFFF !important; }
    .total-num { font-size: 24px; font-weight: 900; color: #000000 !important; -webkit-text-fill-color: #000000 !important; }
    .footer { text-align: center; font-size: 11px; color: #000000 !important; -webkit-text-fill-color: #000000 !important; border-top: 1px dashed #000000; padding-top: 12px; margin-top: 14px; }
    @media print {
      body { background-color: #FFF !important; color: #000 !important; -webkit-text-fill-color: #000 !important; padding: 0; }
      .actions { display: none !important; }
      .card { border: none; box-shadow: none; padding: 0; }
    }
  </style>
</head>
<body style="background-color: #FFFFFF !important; color: #000000 !important; -webkit-text-fill-color: #000000 !important;">
  <div class="container">
    <div class="actions">
      <button class="btn btn-download" onclick="downloadPdf()">
        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
        Download PDF Invoice
      </button>
      <button class="btn btn-print" onclick="window.print()">Print</button>
    </div>

    <div class="card" id="invoice-capture" style="background-color: #FFFFFF !important; color: #000000 !important; -webkit-text-fill-color: #000000 !important;">
      <div class="tax-header">
        <div class="tax-title">RETAIL TAX INVOICE / CASH MEMO</div>
        <h1 class="title">${shopName}</h1>
        ${ownerName ? `<div style="font-size: 12px; font-weight: 700; color: #000000; -webkit-text-fill-color: #000000;">Proprietor: ${ownerName}</div>` : ""}
        <div style="font-size: 12px; color: #000000; -webkit-text-fill-color: #000000;">${shopAddress}</div>
        <div style="font-size: 12px; color: #000000; -webkit-text-fill-color: #000000;">Contact: ${shopPhone}${shopGstin ? ` | GSTIN: ${shopGstin}` : ""}</div>
      </div>

      <table class="info-table">
        <tr>
          <td><strong>Invoice #:</strong> #${orderId}</td>
          <td><strong>Date:</strong> ${dateStr}</td>
        </tr>
        <tr>
          <td><strong>Customer:</strong> ${payerName}</td>
          <td><strong>Payment Mode:</strong> ECO-WALLET (${statusStr})</td>
        </tr>
      </table>
      
      <div class="total-box">
        <span style="font-size: 14px; font-weight: 800; color: #000000; -webkit-text-fill-color: #000000;">TOTAL AMOUNT PAID</span>
        <span class="total-num">₹${Number(amount).toFixed(2)}</span>
      </div>

      <div style="display: flex; justify-content: space-between; align-items: center; margin: 14px 0; padding: 12px 14px; border: 1.5px solid #000000; background-color: #FFFFFF; border-radius: 8px;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent(orderId)}" style="width: 70px; height: 70px; display: block; background: #FFFFFF;" alt="Invoice QR" crossOrigin="anonymous" />
          <div>
            <div style="font-size: 11px; font-weight: 900; color: #000000; -webkit-text-fill-color: #000000; letter-spacing: 0.5px; text-transform: uppercase;">SCAN TO RETURN / VERIFY</div>
            <div style="font-size: 10px; color: #000000; -webkit-text-fill-color: #000000; margin-top: 2px;">Scan this QR with the app to process return</div>
            <div style="font-size: 11px; font-weight: 800; color: #000000; -webkit-text-fill-color: #000000; margin-top: 2px;">ORDER ID: #${orderId}</div>
          </div>
        </div>
        <div style="text-align: right; font-size: 10px; color: #000000; -webkit-text-fill-color: #000000;">
          <div style="font-weight: 700; color: #000000; -webkit-text-fill-color: #000000;">DIGITALLY VERIFIED</div>
          <div style="color: #000000; -webkit-text-fill-color: #000000; font-size: 9px; margin-top: 2px;">ECO-WALLET POS</div>
        </div>
      </div>

      <div class="footer">
        <div style="font-weight: 700; color: #000000; -webkit-text-fill-color: #000000; margin-bottom: 2px;">Thank you for your business!</div>
        <div style="color: #000000; -webkit-text-fill-color: #000000;">Computer generated receipt • Dukaan Dost Smart Billing</div>
      </div>
    </div>
  </div>

  <script>
    function downloadPdf() {
      var element = document.getElementById('invoice-capture');
      var opt = {
        margin: [8, 8, 8, 8],
        filename: 'Invoice_${orderId}.pdf',
        image: { type: 'jpeg', quality: 1.0 },
        html2canvas: {
          scale: 3,
          useCORS: true,
          backgroundColor: '#FFFFFF',
          logging: false,
          onclone: function(clonedDoc) {
            var style = clonedDoc.createElement('style');
            style.textContent = '* { background: #FFFFFF !important; background-color: #FFFFFF !important; color: #000000 !important; -webkit-text-fill-color: #000000 !important; border-color: #000000 !important; } html, body, #invoice-capture, .card, .container { background: #FFFFFF !important; background-color: #FFFFFF !important; color: #000000 !important; -webkit-text-fill-color: #000000 !important; } table, tr, td, th, div, span, p, h1, h2, h3 { background: #FFFFFF !important; background-color: #FFFFFF !important; color: #000000 !important; -webkit-text-fill-color: #000000 !important; }';
            clonedDoc.head.appendChild(style);

            var clonedElem = clonedDoc.getElementById('invoice-capture');
            if (clonedElem) {
              clonedElem.style.setProperty('background-color', '#FFFFFF', 'important');
              clonedElem.style.setProperty('background', '#FFFFFF', 'important');
              clonedElem.style.setProperty('color', '#000000', 'important');
              clonedElem.style.setProperty('-webkit-text-fill-color', '#000000', 'important');

              var allElements = clonedElem.getElementsByTagName('*');
              for (var i = 0; i < allElements.length; i++) {
                allElements[i].style.setProperty('background-color', '#FFFFFF', 'important');
                allElements[i].style.setProperty('background', '#FFFFFF', 'important');
                allElements[i].style.setProperty('color', '#000000', 'important');
                allElements[i].style.setProperty('-webkit-text-fill-color', '#000000', 'important');
              }
            }
          }
        },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
      };
      html2pdf().set(opt).from(element).save();
    }
  </script>
</body>
</html>
`;

    res.setHeader("Content-Type", "text/html");
    res.send(htmlContent);
  } catch (error) {
    res.status(500).send("Error loading invoice: " + error.message);
  }
};

router.get("/invoice/:bill_id", renderInvoice);

module.exports = {
  router,
  renderInvoice,
};
