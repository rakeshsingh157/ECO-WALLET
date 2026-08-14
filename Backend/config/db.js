/**
 * ECO Wallet — MongoDB Connection (Mongoose)
 * Configured with 5-minute buffer and server selection timeouts for Render
 */
const mongoose = require("mongoose");

mongoose.set("bufferTimeoutMS", 300000); // 5 minutes

const connectDB = async () => {
  const primaryUri = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/eco_wallet";

  const options = {
    serverSelectionTimeoutMS: 300000,
    connectTimeoutMS: 300000,
    socketTimeoutMS: 300000,
  };

  try {
    const conn = await mongoose.connect(primaryUri, options);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.warn(`⚠️ MongoDB Connection Warning: ${error.message}`);
    console.log(`🚀 Starting server in resilient mode...`);
  }
};

module.exports = connectDB;
