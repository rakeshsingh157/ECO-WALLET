/**
 * ECO Wallet — User Model (Mongoose)
 */
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema(
  {
    user_id: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 100,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      sparse: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
      minlength: 8,
    },
    pin: {
      type: String, // bcrypt hashed
      default: null,
    },
    balance: {
      type: Number,
      default: 0,
      min: 0,
    },
    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
    },
      version: {
        type: Number,
        default: 0, // Optimistic concurrency control
      },
      fcmToken: {
        type: String,
        default: null,
      },
      referred_by: {
        type: String,
        default: null,
      },
    },
    {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password
userSchema.methods.matchPassword = async function (entered) {
  return await bcrypt.compare(entered, this.password);
};

// Compare PIN
userSchema.methods.matchPin = async function (entered) {
  if (!this.pin) return true; // No pin set = skip
  return await bcrypt.compare(entered, this.pin);
};

// Never return sensitive fields
userSchema.methods.toPublic = function () {
  return {
    user_id: this.user_id,
    name: this.name,
    email: this.email,
    phone: this.phone,
    balance: this.balance,
    role: this.role,
    has_pin: !!this.pin,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model("User", userSchema);
