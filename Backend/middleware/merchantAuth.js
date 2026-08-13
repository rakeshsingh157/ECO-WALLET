/**
 * ECO Wallet — Merchant API Key Authentication Middleware
 * Validates the X-API-Key header against registered merchants.
 * Used by billing software endpoints (create-payment, check status, etc.)
 */
const Merchant = require("../models/Merchant");

/**
 * Authenticate merchant via API key in X-API-Key header.
 * On success, attaches `req.merchant` with the merchant document.
 */
const merchantAuth = async (req, res, next) => {
  const apiKey = req.headers["x-api-key"];

  if (!apiKey) {
    return res.status(401).json({
      success: false,
      message: "Missing X-API-Key header",
    });
  }

  try {
    // Find all active merchants and check key against each hash.
    // For performance at scale, consider indexing a key prefix.
    const merchants = await Merchant.find({ is_active: true });

    let matched = null;
    for (const merchant of merchants) {
      const isMatch = await merchant.matchApiKey(apiKey);
      if (isMatch) {
        matched = merchant;
        break;
      }
    }

    if (!matched) {
      return res.status(401).json({
        success: false,
        message: "Invalid API key",
      });
    }

    req.merchant = matched;
    next();
  } catch (error) {
    console.error("Merchant auth error:", error);
    return res.status(500).json({
      success: false,
      message: "Authentication error",
    });
  }
};

module.exports = { merchantAuth };
