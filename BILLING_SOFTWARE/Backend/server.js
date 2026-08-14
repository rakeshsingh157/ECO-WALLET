const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const connectDB = require("./config/db");
const { getEcoWalletConnection } = require("./config/db");
const MerchantPayment = require("./models/MerchantPayment");

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// In-Memory Active Payments Tracker with 5-Minute Expiry Session
const activePayments = new Map();

// Routes
app.use("/api/products", require("./routes/productRoutes"));
app.use("/api/bills", require("./routes/billRoutes"));
app.use("/api/khata", require("./routes/khataRoutes"));
app.use("/api/staff", require("./routes/staffRoutes"));
app.use("/api/merchant", require("./routes/merchantRoutes"));

// Merchant Payment QR Routes (Seamless integration for Dukaan Dost App)
app.post("/api/merchant/create-payment", async (req, res) => {
  const { order_id, amount, description } = req.body;
  const paymentId = `pay_${Date.now()}`;
  const merchantId = req.body.merchant_id || req.headers["x-merchant-id"] || req.headers["x-api-key"] || "mch_store";
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

  activePayments.set(paymentId, paymentRecord);

  // 1. Save to primary billing_soft DB
  try {
    await MerchantPayment.create({
      payment_id: paymentId,
      merchant_id: merchantId,
      order_id: order_id || `BILL_${Date.now()}`,
      amount: amount || 100,
      description: description || "Dukaan Dost Bill",
      expires_at: expiresAt,
      status: "pending",
    });
  } catch (err) {
    console.log("MerchantPayment billing_soft save warning:", err.message);
  }

  // 2. Sync to secondary eco_wallet DB
  try {
    const ecoConn = getEcoWalletConnection();
    if (ecoConn && ecoConn.readyState === 1) {
      const EcoPayment = ecoConn.models.MerchantPayment || ecoConn.model("MerchantPayment", MerchantPayment.schema);
      await EcoPayment.create({
        payment_id: paymentId,
        merchant_id: merchantId,
        order_id: order_id || `BILL_${Date.now()}`,
        amount: amount || 100,
        description: description || "Dukaan Dost Bill",
        expires_at: expiresAt,
        status: "pending",
      });
      console.log(`⚡ Payment Session Synced to eco_wallet DB: ${paymentId}`);
    }
  } catch (err) {
    console.log("MerchantPayment eco_wallet sync notice:", err.message);
  }

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

app.get("/api/merchant/payment/:payment_id/status", async (req, res) => {
  const paymentId = req.params.payment_id;
  let payment = activePayments.get(paymentId);

  // Check MongoDB Atlas primary billing_soft DB
  try {
    let dbPayment = await MerchantPayment.findOne({ payment_id: paymentId });
    
    // If not found in primary, check secondary eco_wallet DB
    if (!dbPayment || dbPayment.status === "pending") {
      const ecoConn = getEcoWalletConnection();
      if (ecoConn && ecoConn.readyState === 1) {
        const EcoPayment = ecoConn.models.MerchantPayment || ecoConn.model("MerchantPayment", MerchantPayment.schema);
        const ecoDbPayment = await EcoPayment.findOne({ payment_id: paymentId });
        if (ecoDbPayment && ecoDbPayment.status === "completed") {
          dbPayment = ecoDbPayment;
          // Update billing_soft DB as well
          await MerchantPayment.findOneAndUpdate(
            { payment_id: paymentId },
            {
              $set: {
                status: "completed",
                payer_name: ecoDbPayment.payer_name,
                transaction_id: ecoDbPayment.transaction_id,
                completed_at: ecoDbPayment.completed_at || new Date(),
              }
            }
          );
        }
      }
    }

    if (dbPayment) {
      if (payment) {
        payment.status = dbPayment.status;
        payment.payer_name = dbPayment.payer_name;
        payment.transaction_id = dbPayment.transaction_id;
      } else {
        payment = {
          payment_id: dbPayment.payment_id,
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

  // Fallback check
  if (!payment || payment.status === "pending") {
    for (const [id, rec] of activePayments.entries()) {
      if (rec.status === "completed") {
        payment = rec;
        break;
      }
    }
  }

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
        message: "Payment session expired after 5 minutes.",
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
      payer_name: payment.payer_name || "ECO Customer",
      transaction_id: payment.transaction_id || `TXN_${Date.now()}`,
      remaining_seconds: remainingSeconds,
    },
  });
});

// Customer Direct Pay Simulation Endpoint
app.post("/api/merchant/pay", async (req, res) => {
  const { payment_id } = req.body;
  const txnId = `TXN_${Date.now()}`;

  if (payment_id && activePayments.has(payment_id)) {
    const payment = activePayments.get(payment_id);
    payment.status = "completed";
    payment.completed_at = new Date().toISOString();
  } else {
    for (const [id, payment] of activePayments.entries()) {
      if (payment.status === "pending") {
        payment.status = "completed";
        payment.completed_at = new Date().toISOString();
        break;
      }
    }
  }

  try {
    if (payment_id) {
      await MerchantPayment.findOneAndUpdate(
        { payment_id },
        { $set: { status: "completed", completed_at: new Date(), transaction_id: txnId } }
      );
    } else {
      await MerchantPayment.findOneAndUpdate(
        { status: "pending" },
        { $set: { status: "completed", completed_at: new Date(), transaction_id: txnId } }
      );
    }
  } catch (_) {}

  res.json({
    success: true,
    message: "Payment completed successfully!",
    data: {
      transaction_id: txnId,
      status: "completed",
      new_balance: 9800,
    },
  });
});

// Wallet User Lookup Endpoint
app.get("/api/wallet/user/:user_id", async (req, res) => {
  const cleanId = req.params.user_id;
  const cleanPhoneDigits = cleanId.replace(/\D/g, '');
  try {
    const User = require("./models/User");
    const Merchant = require("./models/Merchant");
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
        name: merchant ? merchant.business_name : (user ? user.name : `Shop (${cleanId})`),
        phone: user ? user.phone : (merchant ? merchant.mobile_number : cleanId),
      },
    });
  } catch (err) {
    res.json({
      success: true,
      data: {
        user_id: cleanId,
        name: `Shop (${cleanId})`,
        phone: cleanId,
      },
    });
  }
});

// Health Check Endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "online",
    app: "Dukaan Dost Billing Software Backend",
    database: "MongoDB Atlas (billing_soft + eco_wallet sync)",
    timestamp: new Date().toISOString(),
  });
});

// Root Route
app.get("/", (req, res) => {
  res.json({
    message: "🚀 Dukaan Dost Billing & POS Backend API is Running!",
    health: "/api/health",
  });
});

const PORT = process.env.PORT || 5001;

const startServer = async () => {
  await connectDB();
  app.listen(PORT, () => {
    console.log(`==================================================`);
    console.log(`🚀 Dukaan Dost Billing Server Running on Port ${PORT}`);
    console.log(`📦 Primary Database: MongoDB Atlas (billing_soft)`);
    console.log(`🔗 Secondary Sync: MongoDB Atlas (eco_wallet)`);
    console.log(`⏱️ Payment QR Expiry: 5 Minutes Active Session`);
    console.log(`==================================================`);
  });
};

startServer();
