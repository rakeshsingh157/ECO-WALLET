/**
 * ECO Wallet — QR Code Service
 * Generates signed QR codes and verifies their integrity
 */
const crypto = require("crypto");
const QRCode = require("qrcode");

const HMAC_SECRET = process.env.QR_HMAC_SECRET || "default_qr_secret";

/**
 * Create a signed QR payload for a user
 */
const createQRPayload = (user_id, amount) => {
  const data = { user_id, ts: Date.now(), ...(amount ? { amount } : {}) };
  const message = JSON.stringify(data);
  const signature = crypto
    .createHmac("sha256", HMAC_SECRET)
    .update(message)
    .digest("hex");

  return JSON.stringify({ ...data, sig: signature });
};

/**
 * Verify a QR payload's signature
 * Returns user_id if valid, null if tampered
 */
const verifyQRPayload = (payload) => {
  try {
    const parsed = JSON.parse(payload);
    const { sig, ...data } = parsed;
    const message = JSON.stringify(data);
    const expected = crypto
      .createHmac("sha256", HMAC_SECRET)
      .update(message)
      .digest("hex");

    if (sig !== expected) return null;

    // Check if QR is not too old (5 minutes)
    const age = Date.now() - data.ts;
    if (age > 5 * 60 * 1000) return null;

    return data.user_id;
  } catch {
    return null;
  }
};

/**
 * Generate QR code as data URL (base64 PNG)
 */
const generateQRDataURL = async (user_id, amount) => {
  const payload = createQRPayload(user_id, amount);
  const dataUrl = await QRCode.toDataURL(payload, {
    width: 300,
    margin: 2,
    color: {
      dark: "#00f5ff",
      light: "#0b1326",
    },
  });
  return { dataUrl, payload };
};

module.exports = { createQRPayload, verifyQRPayload, generateQRDataURL };
