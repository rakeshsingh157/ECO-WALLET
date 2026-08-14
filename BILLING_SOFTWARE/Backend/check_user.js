const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');

dotenv.config();

async function check() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error(' MONGO_URI missing in .env');
    return;
  }
  await mongoose.connect(uri);
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
