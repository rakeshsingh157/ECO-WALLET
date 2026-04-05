
const express = require("express");
const mongoose = require("mongoose");
const { protect } = require("../middleware/auth");
const User = require("../models/User");
const Task = require("../models/Task");
const TaskProgress = require("../models/TaskProgress");
const Bank = require("../models/Bank");
const Transaction = require("../models/Transaction");
const { generateTransactionId } = require("../utils/idGenerator");
const { auditLog } = require("../utils/logger");
const { notify, notifyAll } = require("../utils/notificationService");

const router = express.Router();

/**
 * Helper: Check if a daily task was already claimed today by a user
 */
async function wasDailyTaskClaimedToday(userId, taskId) {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todayEnd = new Date();
  todayEnd.setHours(23, 59, 59, 999);

  const claimedToday = await TaskProgress.findOne({
    user_id: userId,
    task_id: taskId,
    status: "completed",
    completed_at: { $gte: todayStart, $lte: todayEnd },
  });

  return !!claimedToday;
}

/**
 * Helper: Check if a task is repeatable (ad, daily, etc.)
 */
function isTaskRepeatable(task) {
  return task.repeatable || task.category === 'ad' || task.category === 'daily';
}

/**
 * @route   GET /api/rewards/tasks
 * @desc    List all available tasks for the user
 */
router.get("/tasks", protect, async (req, res) => {
  try {
    const tasks = await Task.find({ active: true }).lean();
    const userId = req.user.user_id;

    // For daily tasks, we need to check if already claimed today
    const enriched = await Promise.all(tasks.map(async (task) => {
      let completed = false;
      const repeatable = isTaskRepeatable(task);

      if (task.category === 'daily') {
        // Daily tasks: completed = true only if already claimed today
        completed = await wasDailyTaskClaimedToday(userId, task.task_id);
      } else if (repeatable) {
        // Ad tasks and other repeatables: never show as completed
        completed = false;
      } else {
        // One-time tasks: check if user is in completed_by
        completed = task.completed_by.includes(userId);
      }

      return {
        task_id: task.task_id,
        title: task.title,
        description: task.description,
        reward_amount: task.reward_amount,
        icon: task.icon,
        category: task.category,
        completed,
        active: task.active,
        repeatable,
      };
    }));

    // Get weekly earnings
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const weeklyEarnings = await Transaction.aggregate([
      {
        $match: {
          receiver_id: userId,
          type: "reward",
          timestamp: { $gte: weekAgo },
        },
      },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    res.json({
      success: true,
      data: {
        tasks: enriched,
        weekly_earnings: weeklyEarnings[0]?.total || 0,
      },
    });
  } catch (error) {
    console.error("Tasks error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   POST /api/rewards/start/:task_id
 * @desc    Start a task
 */
router.post("/start/:task_id", protect, async (req, res) => {
  try {
    const userId = req.user.user_id;
    const { task_id } = req.params;

    const task = await Task.findOne({ task_id, active: true });
    if (!task) {
      return res.status(404).json({ success: false, message: "Task not found" });
    }

    const repeatable = isTaskRepeatable(task);

    // For daily tasks, check if already claimed today
    if (task.category === 'daily') {
      const alreadyClaimed = await wasDailyTaskClaimedToday(userId, task_id);
      if (alreadyClaimed) {
        return res.status(400).json({ success: false, message: "Daily reward already claimed today. Come back tomorrow!" });
      }
    }

    if (!repeatable && task.completed_by.includes(userId)) {
      return res.status(400).json({ success: false, message: "Task already completed" });
    }

    // Check existing progress
    const existing = await TaskProgress.findOne({ user_id: userId, task_id });
    if (existing) {
      if (existing.status === "started") {
        existing.started_at = Date.now();
        await existing.save();
        return res.json({ success: true, message: "Task restarted" });
      } else if (repeatable) {
        await TaskProgress.deleteOne({ _id: existing._id });
      } else {
        return res.status(400).json({ success: false, message: "Task already completed" });
      }
    }

    await TaskProgress.create({
      user_id: userId,
      task_id,
      status: "started",
    });

    res.json({ success: true, message: "Task started" });
  } catch (error) {
    console.error("Start task error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   POST /api/rewards/complete/:task_id
 * @desc    Complete a task and earn reward (server-verified)
 */
router.post("/complete/:task_id", protect, async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const userId = req.user.user_id;
    const { task_id } = req.params;

    // Get bank status
    const bank = await Bank.findOne({}).session(session);
    if (!bank || bank.status === "exhausted") {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: "All rewards have been exhausted. Only transfers available.",
      });
    }

    // Get task
    const task = await Task.findOne({ task_id, active: true }).session(session);
    if (!task) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ success: false, message: "Task not found" });
    }

    // Check if already completed by this user (and not repeatable)
    const repeatable = isTaskRepeatable(task);

    // For daily tasks, check if already claimed today
    if (task.category === 'daily') {
      const alreadyClaimed = await wasDailyTaskClaimedToday(userId, task_id);
      if (alreadyClaimed) {
        await session.abortTransaction();
        session.endSession();
        return res.status(400).json({
          success: false,
          message: "Daily reward already claimed today. Come back tomorrow!",
        });
      }
    }

    if (!repeatable && task.completed_by.includes(userId)) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: "Task already completed",
      });
    }

    // Verify task progress
    const progress = await TaskProgress.findOne({ user_id: userId, task_id, status: "started" }).session(session);
    if (!progress) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ success: false, message: "Task has not been started. Start the task first." });
    }

    const elapsedMs = Date.now() - new Date(progress.started_at).getTime();
    // Tasks with custom server-side verification or immediate claims don't need timing gates
    const hasCustomVerification = ["Complete Profile", "First Transaction", "Invite Friends"].includes(task.title);
    const minTime = (task.category === 'ad') ? 5000 : 
                    (task.category === 'daily' || hasCustomVerification) ? 0 : 1000;
    if (elapsedMs < minTime) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ success: false, message: "Task verification failed. Please wait a moment and try again." });
    }

    // === CUSTOM VERIFICATION LOGIC ===
    if (task.title === "Complete Profile") {
      const userDoc = await User.findOne({ user_id: userId }).session(session);
      const hasPhone = userDoc.phone && userDoc.phone.trim().length >= 10;
      const hasPin = !!userDoc.pin;
      if (!hasPhone || !hasPin) {
        await session.abortTransaction();
        session.endSession();
        const missing = [];
        if (!hasPhone) missing.push("Phone Number");
        if (!hasPin) missing.push("Payment PIN");
        return res.status(400).json({ success: false, message: `Please set your ${missing.join(" and ")} in the Profile tab first.` });
      }
    } else if (task.title === "First Transaction") {
      const txnUser = await Transaction.findOne({ sender_id: userId, type: "transfer", status: "success" });
      if (!txnUser) {
        await session.abortTransaction();
        session.endSession();
        return res.status(400).json({ success: false, message: "You must send at least 1 successful peer-to-peer transfer first!" });
      }
    } else if (task.title === "Invite Friends") {
      // Check if at least 1 user used this user's referral code
      const referralCount = await User.countDocuments({ referred_by: userId });
      if (referralCount < 1) {
        await session.abortTransaction();
        session.endSession();
        return res.status(400).json({ success: false, message: "Share your referral code with friends. At least 1 friend must sign up using your code!" });
      }
    }

    // Update progress — for daily tasks, save completion with timestamp so we can check daily claims
    progress.status = "completed";
    progress.completed_at = new Date();
    await progress.save({ session });
    
    // For ad-type repeatable tasks, delete progress so they can start again.
    // For daily tasks, keep the completed progress record (we need it for the daily check).
    if (task.category === 'ad' || (repeatable && task.category !== 'daily')) {
      await TaskProgress.deleteOne({ _id: progress._id }, { session });
    }

    // Check bank balance
    if (bank.total_balance < task.reward_amount) {
      // Bank exhausted by this task
      bank.status = "exhausted";
      bank.total_balance = 0;
      await bank.save({ session });

      await session.commitTransaction();
      session.endSession();

      // Broadcast exhaustion
      await notifyAll("alert", "Bank Exhausted", "All ECO rewards have been distributed. Only peer-to-peer transfers are available.");

      return res.status(400).json({
        success: false,
        message: "Insufficient bank balance for this reward",
      });
    }

    // Deduct from bank
    bank.total_balance -= task.reward_amount;
    bank.total_distributed += task.reward_amount;
    if (bank.total_balance <= 0) {
      bank.status = "exhausted";
    }
    await bank.save({ session });

    // Credit user
    await User.findOneAndUpdate(
      { user_id: userId },
      { $inc: { balance: task.reward_amount, version: 1 } },
      { session }
    );

    // Mark task as completed by user
    await Task.findOneAndUpdate(
      { task_id },
      { $addToSet: { completed_by: userId } },
      { session }
    );

    // Create transaction
    const txn_id = generateTransactionId();
    await Transaction.create(
      [
        {
          transaction_id: txn_id,
          sender_id: "BANK",
          receiver_id: userId,
          amount: task.reward_amount,
          type: "reward",
          status: "success",
          description: `Reward: ${task.title}`,
          sender_name: "ECO Bank",
          receiver_name: req.user.name,
          timestamp: new Date(),
        },
      ],
      { session }
    );

    // === AUTOMATIC REFERRAL REWARD PIPELINE ===
    if (task.title === "First Transaction") {
      const userDocRef = await User.findOne({ user_id: userId }).session(session);
      if (userDocRef && userDocRef.referred_by) {
        const referrer = await User.findOne({ user_id: userDocRef.referred_by }).session(session);
        if (referrer && bank.total_balance >= 500) {
           referrer.balance += 500;
           await referrer.save({ session });

           bank.total_balance -= 500;
           bank.total_distributed += 500;
           if (bank.total_balance <= 0) bank.status = "exhausted";
           await bank.save({ session });

           const refTxnId = generateTransactionId();
           await Transaction.create([{
              transaction_id: refTxnId,
              sender_id: "BANK",
              receiver_id: referrer.user_id,
              amount: 500,
              type: "reward",
              status: "success",
              description: `Referral Bonus for inviting ${userDocRef.name}`,
              sender_name: "ECO Bank",
              receiver_name: referrer.name,
              timestamp: new Date()
           }], { session });

           // Queue notification later
           setTimeout(async () => {
             await notify(referrer.user_id, "reward", "Referral Bonus", `You earned 500 ECO because ${userDocRef.name} completed their first transaction!`, { transaction_id: refTxnId });
           }, 1000);
        }
      }
    }

    await session.commitTransaction();
    session.endSession();

    // Notifications
    await notify(
      userId,
      "reward",
      "Reward Earned",
      `You earned ${task.reward_amount} ECO for completing "${task.title}"`,
      { transaction_id: txn_id, task_id }
    );

    await auditLog(
      "TASK_COMPLETE",
      userId,
      `Completed task ${task_id}, earned ${task.reward_amount} ECO`,
      { task_id, reward: task.reward_amount, transaction_id: txn_id },
      req.ip
    );

    // Get updated balance
    const updatedUser = await User.findOne({ user_id: userId }).select("balance");

    res.json({
      success: true,
      message: `Earned ${task.reward_amount} ECO coins.`,
      data: {
        transaction_id: txn_id,
        reward: task.reward_amount,
        new_balance: updatedUser.balance,
        task_id,
      },
    });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error("Task completion error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/rewards/leaderboard
 * @desc    Top earners leaderboard
 */
router.get("/leaderboard", protect, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;

    const leaders = await User.find({ role: "user" })
      .select("user_id name balance")
      .sort({ balance: -1 })
      .limit(limit)
      .lean();

    res.json({
      success: true,
      data: leaders.map((u, i) => ({
        rank: i + 1,
        user_id: u.user_id,
        name: u.name,
        balance: u.balance,
      })),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});
/**
 * @route   GET /api/rewards/referrals
 * @desc    Get user's referrals and their status
 */
router.get("/referrals", protect, async (req, res) => {
  try {
    const userId = req.user.user_id;

    // Find all users who used this user's code
    const referrals = await User.find({ referred_by: userId })
      .select("user_id name email createdAt")
      .lean();

    // Check if each has completed a transfer
    const updatedReferrals = await Promise.all(
      referrals.map(async (friend) => {
        const hasTransaction = await Transaction.findOne({
          sender_id: friend.user_id,
          type: "transfer",
          status: "success",
        }).lean();

        return {
          user_id: friend.user_id,
          name: friend.name,
          email: friend.email,
          joinedAt: friend.createdAt,
          hasCompletedTransaction: !!hasTransaction,
        };
      })
    );

    res.json({
      success: true,
      data: updatedReferrals,
    });
  } catch (error) {
    console.error("Referrals error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
