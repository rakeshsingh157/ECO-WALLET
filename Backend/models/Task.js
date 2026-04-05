/**
 * ECO Wallet — Task Model (Reward System)
 */
const mongoose = require("mongoose");

const taskSchema = new mongoose.Schema(
  {
    task_id: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    reward_amount: {
      type: Number,
      required: true,
      min: 1,
    },
    icon: {
      type: String,
      default: "star",
    },
    category: {
      type: String,
      enum: ["referral", "daily", "ad", "general", "staking"],
      default: "general",
    },
    completed_by: {
      type: [String], // Array of user_ids who completed
      default: [],
    },
    max_completions: {
      type: Number,
      default: null, // null = once per user, unless repeatable is true
    },
    repeatable: {
      type: Boolean,
      default: false,
    },
    active: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Task", taskSchema);
