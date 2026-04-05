/**
 * ECO Wallet — Transaction History Routes
 * GET /api/transactions         — Paginated history
 * GET /api/transactions/:id     — Single transaction
 */
const express = require("express");
const { protect } = require("../middleware/auth");
const Transaction = require("../models/Transaction");

const router = express.Router();

/**
 * @route   GET /api/transactions
 * @desc    Get transaction history with filters
 * @query   filter=all|sent|received  page=1  limit=20
 */
router.get("/", protect, async (req, res) => {
  try {
    const { filter = "all", page = 1, limit = 20 } = req.query;
    const userId = req.user.user_id;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    let query = {};
    if (filter === "sent") {
      query = { sender_id: userId };
    } else if (filter === "received") {
      query = { receiver_id: userId };
    } else {
      query = { $or: [{ sender_id: userId }, { receiver_id: userId }] };
    }

    const [transactions, total] = await Promise.all([
      Transaction.find(query)
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Transaction.countDocuments(query),
    ]);

    // Annotate with direction for the user
    const annotated = transactions.map((txn) => ({
      ...txn,
      direction: txn.sender_id === userId ? "sent" : "received",
    }));

    res.json({
      success: true,
      data: {
        transactions: annotated,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error("Transaction history error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

/**
 * @route   GET /api/transactions/:id
 * @desc    Get a single transaction by ID
 */
router.get("/:id", protect, async (req, res) => {
  try {
    const txn = await Transaction.findOne({
      transaction_id: req.params.id,
      $or: [
        { sender_id: req.user.user_id },
        { receiver_id: req.user.user_id },
      ],
    }).lean();

    if (!txn) {
      return res.status(404).json({
        success: false,
        message: "Transaction not found",
      });
    }

    txn.direction = txn.sender_id === req.user.user_id ? "sent" : "received";

    res.json({ success: true, data: txn });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
