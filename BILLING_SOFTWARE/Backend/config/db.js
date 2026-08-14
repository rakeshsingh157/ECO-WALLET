const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config();

mongoose.set("bufferTimeoutMS", 300000);

let ecoWalletConn = null;

const connectDB = async () => {
  const billingUri = process.env.MONGO_URI;
  const ecoWalletUri = process.env.ECO_WALLET_MONGO_URI;

  if (!billingUri) {
    console.error("[ERROR] MONGO_URI is missing in .env");
    process.exit(1);
  }

  const options = {
    serverSelectionTimeoutMS: 300000,
    connectTimeoutMS: 300000,
    socketTimeoutMS: 300000,
  };

  try {
    const conn = await mongoose.connect(billingUri, options);
    console.log(`[INFO] Connected to primary database: ${conn.connection.name}`);

    if (ecoWalletUri) {
      try {
        ecoWalletConn = mongoose.createConnection(ecoWalletUri, options);
        ecoWalletConn.on("connected", () => {
          console.log(`[INFO] Connected to secondary database: ${ecoWalletConn.name}`);
        });
        ecoWalletConn.on("error", (err) => {
          console.warn(`[WARN] Secondary database notice: ${err.message}`);
        });
      } catch (secErr) {
        console.warn(`[WARN] Secondary connection error: ${secErr.message}`);
      }
    }
  } catch (error) {
    console.error(`[ERROR] Database connection failed: ${error.message}`);
  }
};

const getEcoWalletConnection = () => ecoWalletConn;

module.exports = connectDB;
module.exports.getEcoWalletConnection = getEcoWalletConnection;
