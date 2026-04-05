/**
 * ECO Wallet — Transaction Model
 */
const mongoose = require("mongoose");

const transactionSchema = new mongoose.Schema({
  transaction_id: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  sender_id: {
    type: String,
    required: true, // "BANK" for rewards/minting
    index: true,
  },
  receiver_id: {
    type: String,
    required: true,
    index: true,
  },
  amount: {
    type: Number,
    required: true,
    min: 0.01,
  },
  type: {
    type: String,
    enum: ["transfer", "reward", "mint"],
    required: true,
  },
  status: {
    type: String,
    enum: ["success", "failed", "pending"],
    default: "success",
  },
  description: {
    type: String,
    maxlength: 200,
    default: null,
  },
  sender_name: {
    type: String,
    default: null,
  },
  receiver_name: {
    type: String,
    default: null,
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

// Compound indexes for efficient history queries
transactionSchema.index({ sender_id: 1, timestamp: -1 });
transactionSchema.index({ receiver_id: 1, timestamp: -1 });

module.exports = mongoose.model("Transaction", transactionSchema);
