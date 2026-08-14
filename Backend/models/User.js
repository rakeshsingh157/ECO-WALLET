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
    },
    pin: {
      type: String,
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
      default: 0,
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

userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  const raw = String(this.password || "").trim();
  if (raw.startsWith("$2a$") || raw.startsWith("$2b$") || raw.startsWith("$2y$")) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(raw, salt);
  next();
});

userSchema.methods.matchPassword = async function (entered) {
  const rawEntered = String(entered || "").trim();
  const rawStored = String(this.password || "").trim();
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

userSchema.methods.matchPin = async function (entered) {
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
