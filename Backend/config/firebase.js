/**
 * ECO Wallet — Firebase Admin Configuration
 */
const admin = require("firebase-admin");

try {
  // Try to load service account from env or file
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT 
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
    : null;

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log("Firebase Admin initialized with service account.");
  } else {
    // Fallback for development if no account provided yet
    admin.initializeApp({
        projectId: "eco-wallet-816c3" // From user's config
    });
    console.log("Firebase Admin initialized with Project ID only (limited features).");
  }
} catch (error) {
  console.error("Firebase Admin init error:", error.message);
}

module.exports = admin;
