const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config();

let ecoWalletConn = null;

const connectDB = async () => {
  const billingUri = process.env.MONGO_URI;
  const ecoWalletUri = process.env.ECO_WALLET_MONGO_URI;

  if (!billingUri) {
    console.error("❌ ERROR: MONGO_URI is missing in .env");
    process.exit(1);
  }

  const options = {
    serverSelectionTimeoutMS: 15000,
    connectTimeoutMS: 15000,
  };

  try {
    // 1. Connect primary database: billing_soft
    const conn = await mongoose.connect(billingUri, options);
    console.log(`✅ MongoDB Atlas Primary Connected: ${conn.connection.host} [DB: ${conn.connection.name}]`);

    // 2. Establish secondary connection: eco_wallet
    if (ecoWalletUri) {
      try {
        ecoWalletConn = mongoose.createConnection(ecoWalletUri, options);
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
  }
};

const getEcoWalletConnection = () => ecoWalletConn;

module.exports = connectDB;
module.exports.getEcoWalletConnection = getEcoWalletConnection;
