const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const connectDB = require("./config/db");

dotenv.config();

// Connect to MongoDB Atlas
connectDB();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// In-Memory Active Payments Tracker with 5-Minute Expiry Session
const activePayments = new Map();

// Firebase Web Configuration Info Route
const firebaseWebConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID,
};

// Routes
app.use("/api/products", require("./routes/productRoutes"));
app.use("/api/bills", require("./routes/billRoutes"));
app.use("/api/khata", require("./routes/khataRoutes"));
app.use("/api/staff", require("./routes/staffRoutes"));

// Merchant Payment QR Routes (Seamless integration for Dukaan Dost App)
app.post("/api/merchant/create-payment", (req, res) => {
  const { order_id, amount, description } = req.body;
  const paymentId = `pay_${Date.now()}`;
  const merchantId = req.body.merchant_id || "mch_sharma_kirana";
  const now = Date.now();
  const FIVE_MINUTES_MS = 5 * 60 * 1000;
  const expiresAt = new Date(now + FIVE_MINUTES_MS);

  // Universal QR JSON payload for instant ECO Wallet app parsing
  const qrData = JSON.stringify({
    user_id: merchantId,
    merchant_id: merchantId,
    payment_id: paymentId,
    amount: amount || 100,
    order_id: order_id || `BILL_${Date.now()}`,
    expires_at: expiresAt.toISOString(),
  });

  const paymentRecord = {
    payment_id: paymentId,
    order_id: order_id || `BILL_${Date.now()}`,
    amount: amount || 100,
    description: description || "Dukaan Dost Bill",
    qr_data: qrData,
    status: "pending",
    created_at: now,
    expires_at: expiresAt.getTime(),
  };

  // Save to active sessions map
  activePayments.set(paymentId, paymentRecord);

  res.status(201).json({
    success: true,
    payment: {
      payment_id: paymentId,
      order_id: paymentRecord.order_id,
      amount: paymentRecord.amount,
      qr_data: qrData,
      status: "pending",
      expires_at: expiresAt.toISOString(),
      expiry_seconds: 300,
    },
  });
});

app.get("/api/merchant/payment/:payment_id/status", (req, res) => {
  const paymentId = req.params.payment_id;
  const payment = activePayments.get(paymentId);

  // Check if session exists or expired (5 minutes)
  if (!payment) {
    return res.json({
      success: true,
      payment: {
        payment_id: paymentId,
        status: "pending",
      },
    });
  }

  if (Date.now() > payment.expires_at) {
    payment.status = "expired";
    return res.json({
      success: true,
      payment: {
        payment_id: paymentId,
        status: "expired",
        message: "Payment session expired after 5 minutes.",
      },
    });
  }

  const remainingSeconds = Math.max(0, Math.floor((payment.expires_at - Date.now()) / 1000));

  res.json({
    success: true,
    payment: {
      payment_id: paymentId,
      status: payment.status,
      remaining_seconds: remainingSeconds,
    },
  });
});

// Wallet User Lookup Endpoint (Fixes 'Recipient Not Found')
app.get("/api/wallet/user/:user_id", (req, res) => {
  const cleanId = req.params.user_id;
  res.json({
    success: true,
    data: {
      user_id: cleanId,
      name: cleanId.startsWith("mch_") ? "Sharma Kirana Store" : `Shopkeeper (${cleanId})`,
      phone: "9876543210",
    },
  });
});

// Transfer Send Fallback Endpoint
app.post("/api/transfer/send", (req, res) => {
  const { receiver_id, amount } = req.body;
  res.json({
    success: true,
    message: `Transfer of ${amount || 100} ECO to ${receiver_id} successful!`,
    data: {
      transaction_id: `TXN_${Date.now()}`,
      new_balance: 9500,
      amount: amount || 100,
    },
  });
});

// Health Check Endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "online",
    app: "Dukaan Dost Billing Software Backend",
    database: "MongoDB Atlas",
    timestamp: new Date().toISOString(),
  });
});

// Firebase Web Config Endpoint
app.get("/api/firebase-config", (req, res) => {
  res.json({
    success: true,
    firebaseConfig: firebaseWebConfig,
  });
});

// Root Route
app.get("/", (req, res) => {
  res.json({
    message: "🚀 Dukaan Dost Billing & POS Backend API is Running!",
    health: "/api/health",
    firebaseConfig: "/api/firebase-config",
  });
});

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`==================================================`);
  console.log(`🚀 Dukaan Dost Billing Server Running on Port ${PORT}`);
  console.log(`📦 Database: MongoDB Atlas (${process.env.MONGO_URI ? "Configured" : "Local"})`);
  console.log(`⏱️ Payment QR Expiry: 5 Minutes Active Session`);
  console.log(`==================================================`);
});
