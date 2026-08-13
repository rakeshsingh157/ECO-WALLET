const mongoose = require("mongoose");

const StaffMemberSchema = new mongoose.Schema(
  {
    member_id: { type: String, required: true, unique: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    role: { type: String, enum: ["Owner", "Manager", "Cashier", "Helper"], default: "Cashier" },
    pin: { type: String, required: true, default: "1234" },
    active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model("StaffMember", StaffMemberSchema);
