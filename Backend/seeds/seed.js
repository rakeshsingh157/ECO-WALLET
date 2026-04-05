/**
 * ECO Wallet — Database Seed Script
 * Seeds the central bank and default admin on first boot.
 * Run: node seeds/seed.js
 */
require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const Bank = require("../models/Bank");
const Task = require("../models/Task");
const { generateUserId, generateTaskId } = require("../utils/idGenerator");

const seedDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ Connected to MongoDB for seeding");

    // --- Seed Central Bank ---
    const existingBank = await Bank.findOne({});
    if (!existingBank) {
      const initialBalance = parseFloat(process.env.INITIAL_BANK_BALANCE) || 100000;
      await Bank.create({
        total_balance: initialBalance,
        status: "active",
        total_minted: initialBalance,
        total_distributed: 0,
        daily_minted: 0,
      });
      console.log(`🏦 Central Bank seeded with ${initialBalance} ECO coins`);
    } else {
      console.log("🏦 Central Bank already exists, skipping");
    }

    // --- Seed Admin User ---
    const adminEmail = process.env.ADMIN_EMAIL || "admin@ecowallet.io";
    const existingAdmin = await User.findOne({ email: adminEmail });
    if (!existingAdmin) {
      const adminId = generateUserId();
      await User.create({
        user_id: adminId,
        name: process.env.ADMIN_NAME || "ECO Admin",
        email: adminEmail,
        password: process.env.ADMIN_PASSWORD || "Admin@EcoWallet2026",
        balance: 0,
        role: "admin",
      });
      console.log(`👤 Admin created: ${adminEmail} (ID: ${adminId})`);
    } else {
      console.log("👤 Admin already exists, skipping");
    }

    // --- Seed Default Tasks ---
    const taskCount = await Task.countDocuments();
    if (taskCount === 0) {
      const tasks = [
        {
          task_id: generateTaskId(),
          title: "Invite Friends",
          description: "Expand the ecosystem. Earn 500 ECO for every friend who completes their first transaction.",
          reward_amount: 500,
          icon: "group_add",
          category: "referral",
        },
        {
          task_id: generateTaskId(),
          title: "Watch Ads",
          description: "Support sustainable initiatives. Watch a short video to earn ECO coins.",
          reward_amount: 10,
          icon: "play_circle",
          category: "ad",
          repeatable: true,
        },
        {
          task_id: generateTaskId(),
          title: "Daily Login",
          description: "Keep the streak alive. Log in daily to earn bonus ECO coins.",
          reward_amount: 25,
          icon: "login",
          category: "daily",
        },
        {
          task_id: generateTaskId(),
          title: "Connect Wallet",
          description: "Bridge your assets to the ether. Complete wallet setup to earn rewards.",
          reward_amount: 100,
          icon: "account_balance_wallet",
          category: "general",
        },
        {
          task_id: generateTaskId(),
          title: "Green Stake",
          description: "Stake 50 ECO for 24 hours to earn bonus coins.",
          reward_amount: 45,
          icon: "eco",
          category: "staking",
        },
        {
          task_id: generateTaskId(),
          title: "Complete Profile",
          description: "Add your phone number and set a payment PIN for enhanced security.",
          reward_amount: 50,
          icon: "badge",
          category: "general",
        },
        {
          task_id: generateTaskId(),
          title: "First Transaction",
          description: "Send your first ECO transfer to any user on the network.",
          reward_amount: 75,
          icon: "send",
          category: "general",
        },
      ];

      await Task.insertMany(tasks);
      console.log(`🎯 ${tasks.length} default tasks seeded`);
    } else {
      console.log("🎯 Tasks already exist, skipping");
    }

    console.log("\n🌱 Seed complete!\n");
    process.exit(0);
  } catch (error) {
    console.error("❌ Seed error:", error);
    process.exit(1);
  }
};

seedDB();
