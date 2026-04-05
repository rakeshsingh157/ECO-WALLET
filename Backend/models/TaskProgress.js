/**
 * ECO Wallet — Task Progress Model (Reward Verification)
 */
const mongoose = require("mongoose");

const taskProgressSchema = new mongoose.Schema(
  {
    user_id: {
      type: String,
      required: true,
      index: true,
    },
    task_id: {
      type: String,
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ["started", "completed"],
      default: "started",
    },
    started_at: {
      type: Date,
      default: Date.now,
    },
    completed_at: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Prevent duplicate active tasks
taskProgressSchema.index({ user_id: 1, task_id: 1 }, { unique: true });

module.exports = mongoose.model("TaskProgress", taskProgressSchema);
