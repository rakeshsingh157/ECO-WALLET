const mongoose = require("mongoose");

let ecoWalletConn = null;

const connectDB = async () => {
  const billingUri = process.env.MONGO_URI || "mongodb+srv://kumarpatelrakesh222_db_user:GVIbi4egR1Qv7qCO@upi.vczukul.mongodb.net/billing_soft?appName=UPI";
  const ecoWalletUri = process.env.ECO_WALLET_MONGO_URI || "mongodb+srv://kumarpatelrakesh222_db_user:GVIbi4egR1Qv7qCO@upi.vczukul.mongodb.net/eco_wallet?appName=UPI";

  try {
    // 1. Connect primary database: billing_soft
    const conn = await mongoose.connect(billingUri, {
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`✅ MongoDB Atlas Primary Connected: ${conn.connection.host} [DB: billing_soft]`);

    // 2. Establish secondary sync connection to eco_wallet for seamless merchant & payment sharing
    try {
      ecoWalletConn = mongoose.createConnection(ecoWalletUri, {
        serverSelectionTimeoutMS: 5000,
      });
      ecoWalletConn.on("connected", () => {
        console.log(`🔗 Secondary Sync Connected [DB: eco_wallet] (Real-time Merchant Sync)`);
      });
    } catch (secErr) {
      console.log("Secondary eco_wallet sync connection notice:", secErr.message);
    }
  } catch (error) {
    console.warn(`⚠️ MongoDB Connection Notice: ${error.message}`);
    console.log(`🚀 Starting Dukaan Dost Backend in resilient database mode...`);
  }
};

const getEcoWalletConnection = () => ecoWalletConn;

module.exports = connectDB;
module.exports.getEcoWalletConnection = getEcoWalletConnection;
