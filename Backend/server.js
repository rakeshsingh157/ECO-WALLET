
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const connectDB = require("./config/db");
const path = require("path");


const authRoutes = require("./routes/authRoutes");
const walletRoutes = require("./routes/walletRoutes");
const transferRoutes = require("./routes/transferRoutes");
const transactionRoutes = require("./routes/transactionRoutes");
const rewardRoutes = require("./routes/rewardRoutes");
const adminRoutes = require("./routes/adminRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const merchantModule = require("./routes/merchantRoutes");
const merchantRoutes = merchantModule.router || merchantModule;
const renderInvoice = merchantModule.renderInvoice;

const Bank = require("./models/Bank");
const User = require("./models/User");
const Task = require("./models/Task");
const { generateUserId, generateTaskId } = require("./utils/idGenerator");

const app = express();

app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: false,
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

const corsOrigins = (process.env.CORS_ORIGINS || "").split(",").map((s) => s.trim()).filter(Boolean);
app.use(
  cors({
    origin: corsOrigins.length > 0 ? corsOrigins : "*",
    credentials: true,
  })
);

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

if (process.env.NODE_ENV !== "production") {
  app.use(morgan("dev"));
}

const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_PER_MINUTE) || 60,
  message: { success: false, message: "Too many requests, please try again later" },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api/", globalLimiter);

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: parseInt(process.env.LOGIN_RATE_LIMIT) || 5,
  message: { success: false, message: "Too many login attempts, try again in 15 minutes" },
});
app.use("/api/auth/login", authLimiter);

const transferLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: { success: false, message: "Too many transfer attempts. Please try again later." },
});

const taskLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 15,
  message: { success: false, message: "Too many task actions. Please try again later." },
});

const merchantLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: { success: false, message: "Too many merchant API requests. Please try again later." },
});

app.use("/api/auth", authRoutes);
app.use("/api/wallet", walletRoutes);
app.use("/api/transfer", transferLimiter, transferRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/rewards", taskLimiter, rewardRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/merchant", merchantLimiter, merchantRoutes);

if (renderInvoice) {
  app.get("/api/merchant/invoice/:bill_id", renderInvoice);
  app.get("/api/invoice/:bill_id", renderInvoice);
  app.get("/api/bills/invoice/:bill_id", renderInvoice);
  app.get("/invoice/:bill_id", renderInvoice);
}

// ─── Health Check ───────────────────────────────────────
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "ECO Wallet API is running",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  });
});

// ─── Bank Status (public) ───────────────────────────────
app.get("/api/bank/status", async (req, res) => {
  try {
    const bank = await Bank.findOne({}).select("total_balance status total_distributed").lean();
    res.json({
      success: true,
      data: bank || { total_balance: 0, status: "exhausted", total_distributed: 0 },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ─── Serve Frontend (Static) ────────────────────────────
// NOTE: Disabled — was serving raw Flutter source code, not a web build.
// Uncomment and point to a proper build directory if you create a web frontend.
// app.use(express.static(path.join(__dirname, "../web-build")));

// ─── 404 Handler ────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// ─── Error Handler ──────────────────────────────────────
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ success: false, message: "Internal server error" });
});

// ─── Auto-Seed Function ────────────────────────────────
const autoSeed = async () => {
  try {
    // Seed bank if not exists
    const bank = await Bank.findOne({});
    if (!bank) {
      const initialBalance = parseFloat(process.env.INITIAL_BANK_BALANCE) || 100000;
      await Bank.create({
        total_balance: initialBalance,
        status: "active",
        total_minted: initialBalance,
        total_distributed: 0,
        daily_minted: 0,
      });
      console.log(`🏦 Central Bank auto-seeded: ${initialBalance} ECO`);
    }

    // Seed admin if not exists
    const adminEmail = process.env.ADMIN_EMAIL || "admin@ecowallet.io";
    const admin = await User.findOne({ email: adminEmail });
    if (!admin) {
      const adminId = generateUserId();
      await User.create({
        user_id: adminId,
        name: process.env.ADMIN_NAME || "ECO Admin",
        email: adminEmail,
        password: process.env.ADMIN_PASSWORD || "Admin@EcoWallet2026",
        balance: 0,
        role: "admin",
      });
      console.log(`👤 Admin auto-seeded: ${adminEmail}`);
    }

    // Seed default tasks if none exist
    const taskCount = await Task.countDocuments();
    if (taskCount === 0) {
      const defaultTasks = [
        { task_id: generateTaskId(), title: "Invite Friends", description: "Expand the ecosystem. Earn ECO for referrals.", reward_amount: 500, icon: "group_add", category: "referral" },
        { task_id: generateTaskId(), title: "Watch Ads", description: "Support sustainable initiatives.", reward_amount: 10, icon: "play_circle", category: "ad" },
        { task_id: generateTaskId(), title: "Daily Login", description: "Keep the streak alive.", reward_amount: 25, icon: "login", category: "daily" },
        { task_id: generateTaskId(), title: "Connect Wallet", description: "Bridge your assets to the ether.", reward_amount: 100, icon: "account_balance_wallet", category: "general" },
        { task_id: generateTaskId(), title: "Green Stake", description: "Stake 50 ECO for 24 hours.", reward_amount: 45, icon: "eco", category: "staking" },
        { task_id: generateTaskId(), title: "Complete Profile", description: "Set up your full profile.", reward_amount: 50, icon: "badge", category: "general" },
        { task_id: generateTaskId(), title: "First Transaction", description: "Send your first transfer.", reward_amount: 75, icon: "send", category: "general" },
      ];
      await Task.insertMany(defaultTasks);
      console.log(`🎯 ${defaultTasks.length} default tasks seeded`);
    }
  } catch (err) {
    console.error("Auto-seed error:", err.message);
  }
};

// ─── Start Server ───────────────────────────────────────
const PORT = process.env.PORT || 8000;

const startServer = async () => {
  await connectDB();
  await autoSeed();

  app.listen(PORT, () => {
    console.log(`\n🚀 ECO Wallet API running on http://localhost:${PORT}`);
    console.log(`📊 Health: http://localhost:${PORT}/api/health`);
    console.log(`🏦 Bank:   http://localhost:${PORT}/api/bank/status\n`);
  });
};

startServer();
