const Merchant = require("../models/Merchant");
const User = require("../models/User");

const merchantCache = new Map();
const CACHE_TTL_MS = 60 * 1000;

function extractCleanMerchantId(raw) {
  if (!raw || typeof raw !== "string") return null;
  const str = raw.trim();
  if (!str) return null;

  if (str.startsWith("key_mch_")) {
    const parts = str.replace("key_mch_", "").split("_");
    const digits = parts[0].replace(/\D/g, "");
    if (digits.length >= 10) return `mch_${digits}`;
  }

  if (str.startsWith("mch_")) {
    const digits = str.replace("mch_", "").replace(/\D/g, "");
    if (digits.length >= 10) return `mch_${digits}`;
    return str;
  }

  const cleanDigits = str.replace(/\D/g, "");
  if (cleanDigits.length >= 10) {
    return `mch_${cleanDigits.slice(-10)}`;
  }

  return str;
}

async function resolveMerchant(req, res, next) {
  try {
    const rawKey =
      req.headers["x-api-key"] ||
      req.headers["authorization"]?.replace(/^Bearer\s+/i, "") ||
      req.headers["x-merchant-id"] ||
      req.query.api_key ||
      req.query.merchant_id;

    if (!rawKey) {
      req.merchant_id = "mch_default";
      return next();
    }

    const cacheKey = String(rawKey).trim();
    const cached = merchantCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL_MS) {
      req.merchant_id = cached.merchant_id;
      req.merchant = cached.merchant;
      return next();
    }

    const cleanDigits = String(rawKey).replace(/\D/g, "");
    const possibleIds = [
      rawKey,
      extractCleanMerchantId(rawKey),
      ...(cleanDigits.length >= 10 ? [`mch_${cleanDigits.slice(-10)}`, cleanDigits.slice(-10)] : []),
    ].filter(Boolean);

    const merchant = await Merchant.findOne({
      $or: [
        { merchant_id: { $in: possibleIds } },
        { api_key_hash: rawKey },
        { user_id: { $in: possibleIds } },
        ...(cleanDigits.length >= 10 ? [{ mobile_number: cleanDigits.slice(-10) }] : []),
      ],
    }).lean();

    if (merchant) {
      req.merchant_id = merchant.merchant_id;
      req.merchant = merchant;
      merchantCache.set(cacheKey, { merchant_id: merchant.merchant_id, merchant, timestamp: Date.now() });
      return next();
    }

    const user = await User.findOne({
      $or: [
        { user_id: { $in: possibleIds } },
        ...(cleanDigits.length >= 10 ? [{ phone: cleanDigits.slice(-10) }] : []),
      ],
    }).lean();

    if (user) {
      const resolvedId = user.user_id.startsWith("mch_") ? user.user_id : `mch_${user.phone || user.user_id}`;
      req.merchant_id = resolvedId;
      req.user = user;
      merchantCache.set(cacheKey, { merchant_id: resolvedId, timestamp: Date.now() });
      return next();
    }

    const fallbackId = extractCleanMerchantId(rawKey) || (rawKey.startsWith("mch_") ? rawKey : `mch_${rawKey}`);
    req.merchant_id = fallbackId;
    merchantCache.set(cacheKey, { merchant_id: fallbackId, timestamp: Date.now() });
    next();
  } catch (error) {
    req.merchant_id = "mch_default";
    next();
  }
}

function requireAuth(req, res, next) {
  if (!req.merchant_id || req.merchant_id === "mch_default") {
    return res.status(401).json({
      success: false,
      message: "Authentication required. Please provide a valid API Key or Merchant ID.",
    });
  }
  next();
}

module.exports = {
  resolveMerchant,
  requireAuth,
  extractCleanMerchantId,
};
