const mongoose = require('mongoose');
const User = require('./models/User');
const dotenv = require("dotenv")

async function check() {
  await mongoose.connect('mongodb+srv://kumarpatelrakesh222_db_user:GVIbi4egR1Qv7qCO@upi.vczukul.mongodb.net/billing_soft?appName=UPI');
  const u = await User.findOne({ phone: '6200779484' });
  console.log('User 6200779484 in billing_soft:', {
    user_id: u?.user_id,
    name: u?.name,
    phone: u?.phone,
    password: u?.password,
    pin: u?.pin,
  });
  await mongoose.disconnect();
}
check();
