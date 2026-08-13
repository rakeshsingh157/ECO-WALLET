/**
 * ECO Wallet — Unique ID Generator
 * Generates non-sequential, random, unguessable user IDs like ECO7X9K2P
 */
const crypto = require("crypto");

/**
 * Generate a random ECO user ID
 * Format: ECO + 6 random alphanumeric chars (uppercase)
 * Example: ECO7X9K2P, ECOA3B8MN
 */
const generateUserId = () => {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // No 0/O/1/I confusion
  let id = "ECO";
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    id += chars[bytes[i] % chars.length];
  }
  return id;
};

/**
 * Generate a unique transaction ID
 * Format: TXN + timestamp hex + random bytes
 */
const generateTransactionId = () => {
  const ts = Date.now().toString(16).toUpperCase();
  const rand = crypto.randomBytes(4).toString("hex").toUpperCase();
  return `TXN${ts}${rand}`;
};

/**
 * Generate a unique task ID
 */
const generateTaskId = () => {
  const rand = crypto.randomBytes(4).toString("hex").toUpperCase();
  return `TASK${rand}`;
};

/**
 * Generate a unique merchant ID
 * Format: MRC + 8 random hex chars
 */
const generateMerchantId = () => {
  const rand = crypto.randomBytes(4).toString("hex").toUpperCase();
  return `MRC${rand}`;
};

/**
 * Generate a unique merchant payment ID
 * Format: PAY + timestamp hex + random bytes
 */
const generatePaymentId = () => {
  const ts = Date.now().toString(16).toUpperCase();
  const rand = crypto.randomBytes(4).toString("hex").toUpperCase();
  return `PAY${ts}${rand}`;
};

module.exports = { generateUserId, generateTransactionId, generateTaskId, generateMerchantId, generatePaymentId };
