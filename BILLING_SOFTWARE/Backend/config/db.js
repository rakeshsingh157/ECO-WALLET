const mongoose = require("mongoose");
const dotenv = require("dotenv");

// Ensure environment variables are loaded
dotenv.config();

let ecoWalletConn = null;

const connectDB = async () => {
  const billingUri = process.env.MONGO_URI;
  const ecoWalletUri = process.env.ECO_WALLET_MONGO_URI;

  if (!billingUri) {
    console.error(" ERROR: MONGO_URI is not defined in environment variables (.env)");
    process.exit(1);
  }

  try {
    // 1. Connect primary database: billing_soft
    const conn = await mongoose.connect(billingUri, {
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`✅ MongoDB Atlas Primary Connected: ${conn.connection.host} [DB: ${conn.connection.name}]`);

    // 2. Establish secondary sync connection to eco_wallet for real-time merchant & payment sharing
    if (ecoWalletUri) {
      try {
        ecoWalletConn = mongoose.createConnection(ecoWalletUri, {
          serverSelectionTimeoutMS: 5000,
        });
        ecoWalletConn.on("connected", () => {
          console.log(`🔗 Secondary Sync Connected [DB: ${ecoWalletConn.name}] (Real-time Merchant Sync)`);
        });
        ecoWalletConn.on("error", (err) => {
          console.warn(`⚠️ Secondary eco_wallet sync notice: ${err.message}`);
        });
      } catch (secErr) {
        console.warn(`⚠️ Secondary eco_wallet sync notice: ${secErr.message}`);
      }
    }
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    console.log(`🚀 Starting Dukaan Dost Backend in resilient database mode...`);
  }
};

const getEcoWalletConnection = () => ecoWalletConn;

module.exports = connectDB;
module.exports.getEcoWalletConnection = getEcoWalletConnection;
