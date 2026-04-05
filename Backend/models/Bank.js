/**
 * ECO Wallet — Central Bank Model
 */
const mongoose = require("mongoose");

const bankSchema = new mongoose.Schema(
  {
    total_balance: {
      type: Number,
      required: true,
      default: 100000,
    },
    status: {
      type: String,
      enum: ["active", "exhausted"],
      default: "active",
    },
    total_minted: {
      type: Number,
      default: 100000,
    },
    total_distributed: {
      type: Number,
      default: 0,
    },
    daily_minted: {
      type: Number,
      default: 0,
    },
    daily_mint_date: {
      type: String, // YYYY-MM-DD
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Check if bank is exhausted
bankSchema.methods.isExhausted = function () {
  return this.total_balance <= 0;
};

// Get today's mint amount (resets daily)
bankSchema.methods.getTodayMinted = function () {
  const today = new Date().toISOString().split("T")[0];
  if (this.daily_mint_date !== today) return 0;
  return this.daily_minted;
};

module.exports = mongoose.model("Bank", bankSchema);
