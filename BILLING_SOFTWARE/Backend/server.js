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
  const qrData = `ecowallet://pay?merchant=mch_sharma_kirana&amount=${amount || 100}&payment_id=${paymentId}`;

  res.status(201).json({
    success: true,
    payment: {
      payment_id: paymentId,
      order_id: order_id || `BILL_${Date.now()}`,
      amount: amount || 100,
      qr_data: qrData,
      status: "pending",
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    },
  });
});

app.get("/api/merchant/payment/:payment_id/status", (req, res) => {
  res.json({
    success: true,
    payment: {
      payment_id: req.params.payment_id,
      status: "pending",
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
  console.log(`🔥 Firebase Project ID: ${process.env.FIREBASE_PROJECT_ID}`);
  console.log(`==================================================`);
});
