const mongoose = require("mongoose");
const Task = require("./models/Task");
require("dotenv").config();

async function updateTasks() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const res = await Task.updateMany({ category: "ad" }, { $set: { repeatable: true } });
    console.log(`Tasks updated! Modified ${res.modifiedCount} tasks.`);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}
updateTasks();
