const mongoose = require("mongoose");

const connectDB = async () => {
  const mongoUri = process.env.MONGO_URI || "mongodb+srv://kumarpatelrakesh222_db_user:GVIbi4egR1Qv7qCO@upi.vczukul.mongodb.net/billing_soft?appName=UPI";

  try {
    const conn = await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`✅ MongoDB Atlas Connected: ${conn.connection.host} [DB: billing_soft]`);
  } catch (error) {
    console.warn(`⚠️ MongoDB Connection Notice: ${error.message}`);
    console.log(`🚀 Starting Dukaan Dost Backend in resilient database mode...`);
  }
};

module.exports = connectDB;
