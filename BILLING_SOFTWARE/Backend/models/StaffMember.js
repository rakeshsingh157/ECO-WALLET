const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const StaffMemberSchema = new mongoose.Schema(
  {
    member_id: { type: String, required: true, unique: true, index: true },
    merchant_id: { type: String, default: "mch_default", index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true, index: true },
    role: { type: String, enum: ["Owner", "Shop Manager", "Counter Cashier", "Inventory Helper", "Cashier", "Helper", "Manager"], default: "Counter Cashier" },
    pin: { type: String, required: true, default: "1234" },
    active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

StaffMemberSchema.pre("save", async function (next) {
  if (this.isModified("pin") && this.pin) {
    const raw = String(this.pin).trim();
    if (!raw.startsWith("$2a$") && !raw.startsWith("$2b$") && !raw.startsWith("$2y$")) {
      const salt = await bcrypt.genSalt(10);
      this.pin = await bcrypt.hash(raw, salt);
    }
  }
  next();
});

StaffMemberSchema.methods.matchPin = async function (entered) {
  if (!this.pin) return true;
  const rawEntered = String(entered || "").trim();
  const rawStored = String(this.pin || "").trim();
  try {
    if (rawStored.startsWith("$2a$") || rawStored.startsWith("$2b$") || rawStored.startsWith("$2y$")) {
      const match = await bcrypt.compare(rawEntered, rawStored);
      if (match) return true;
    }
    return rawEntered === rawStored;
  } catch (_) {
    return rawEntered === rawStored;
  }
};

module.exports = mongoose.models.StaffMember || mongoose.model("StaffMember", StaffMemberSchema);
