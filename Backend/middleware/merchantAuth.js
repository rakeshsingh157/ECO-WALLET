const Merchant = require("../models/Merchant");

const merchantAuth = async (req, res, next) => {
  const rawKey = req.headers["x-api-key"] || req.headers["x-merchant-id"] || req.query.api_key;

  if (!rawKey) {
    return res.status(401).json({
      success: false,
      message: "Missing X-API-Key header",
    });
  }

  try {
    const cleanKey = String(rawKey).trim();
    const cleanDigits = cleanKey.replace(/\D/g, "");

    let matched = await Merchant.findOne({
      is_active: true,
      $or: [
        { api_key_hash: cleanKey },
        { merchant_id: cleanKey },
        { user_id: cleanKey },
        ...(cleanDigits.length >= 10 ? [{ mobile_number: cleanDigits }, { merchant_id: `mch_${cleanDigits}` }] : []),
      ],
    });

    if (!matched) {
      const merchants = await Merchant.find({ is_active: true }).limit(50);
      for (const merchant of merchants) {
        const isMatch = await merchant.matchApiKey(cleanKey);
        if (isMatch) {
          matched = merchant;
          break;
        }
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
    return res.status(500).json({
      success: false,
      message: "Authentication error",
    });
  }
};

module.exports = { merchantAuth };
