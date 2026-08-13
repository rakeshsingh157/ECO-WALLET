/**
 * ECO Wallet — Webhook Service
 * Delivers payment notification webhooks to merchant billing backends.
 * 
 * Features:
 * - HMAC-SHA256 signature for payload verification
 * - Retry with exponential backoff (3 attempts)
 * - Delivery status tracking
 */
const crypto = require("crypto");
const MerchantPayment = require("../models/MerchantPayment");

/**
 * Generate HMAC-SHA256 signature for webhook payload
 * @param {string} secret - The merchant's webhook_secret
 * @param {number} timestamp - Unix timestamp (seconds)
 * @param {string} body - JSON-stringified payload body
 * @returns {string} The HMAC signature
 */
const generateSignature = (secret, timestamp, body) => {
  const message = `${timestamp}.${body}`;
  return crypto.createHmac("sha256", secret).update(message).digest("hex");
};

/**
 * Deliver a webhook to the merchant's billing backend
 * @param {Object} merchant - Merchant document (with webhook_url and webhook_secret)
 * @param {Object} payment - MerchantPayment document
 * @param {string} event - Event type (e.g., "payment.completed")
 */
const deliverWebhook = async (merchant, payment, event = "payment.completed") => {
  const MAX_RETRIES = 3;
  const BASE_DELAY_MS = 1000; // 1s, 2s, 4s

  const payload = {
    event,
    payment_id: payment.payment_id,
    order_id: payment.order_id,
    amount: payment.amount,
    status: payment.status,
    payer_id: payment.payer_id,
    payer_name: payment.payer_name,
    transaction_id: payment.transaction_id,
    completed_at: payment.completed_at,
    merchant_id: merchant.merchant_id,
  };

  const bodyString = JSON.stringify(payload);
  const timestamp = Math.floor(Date.now() / 1000);
  const signature = generateSignature(merchant.webhook_secret, timestamp, bodyString);

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

      const response = await fetch(merchant.webhook_url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-ECO-Signature": `sha256=${signature}`,
          "X-ECO-Timestamp": String(timestamp),
          "X-ECO-Event": event,
          "X-ECO-Payment-ID": payment.payment_id,
          "User-Agent": "ECO-Wallet-Webhook/1.0",
        },
        body: bodyString,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        // Success — update delivery status
        await MerchantPayment.findOneAndUpdate(
          { payment_id: payment.payment_id },
          {
            $set: {
              webhook_delivered: true,
              webhook_last_error: null,
            },
            $inc: { webhook_attempts: 1 },
          }
        );
        console.log(`✅ Webhook delivered: ${payment.payment_id} → ${merchant.webhook_url} (attempt ${attempt})`);
        return true;
      }

      // Non-2xx response
      const errorText = await response.text().catch(() => "No body");
      throw new Error(`HTTP ${response.status}: ${errorText.substring(0, 200)}`);
    } catch (error) {
      const errorMessage = error.name === "AbortError" ? "Request timeout (10s)" : error.message;
      console.error(`⚠️ Webhook attempt ${attempt}/${MAX_RETRIES} failed for ${payment.payment_id}: ${errorMessage}`);

      // Update attempt count and error
      await MerchantPayment.findOneAndUpdate(
        { payment_id: payment.payment_id },
        {
          $set: { webhook_last_error: errorMessage },
          $inc: { webhook_attempts: 1 },
        }
      );

      // Wait before retrying (exponential backoff)
      if (attempt < MAX_RETRIES) {
        const delay = BASE_DELAY_MS * Math.pow(2, attempt - 1);
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  console.error(`❌ Webhook delivery failed permanently for ${payment.payment_id} after ${MAX_RETRIES} attempts`);
  return false;
};

/**
 * Verify a webhook signature (for documentation / SDK purposes)
 * The billing software should use this logic to verify incoming webhooks.
 * 
 * @param {string} secret - The merchant's webhook_secret
 * @param {string} signatureHeader - Value of X-ECO-Signature header
 * @param {string} timestampHeader - Value of X-ECO-Timestamp header
 * @param {string} rawBody - Raw request body string
 * @returns {boolean}
 */
const verifyWebhookSignature = (secret, signatureHeader, timestampHeader, rawBody) => {
  const expectedSig = generateSignature(secret, timestampHeader, rawBody);
  const receivedSig = signatureHeader.replace("sha256=", "");
  return crypto.timingSafeEqual(
    Buffer.from(expectedSig, "hex"),
    Buffer.from(receivedSig, "hex")
  );
};

module.exports = { deliverWebhook, generateSignature, verifyWebhookSignature };
