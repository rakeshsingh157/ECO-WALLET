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
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },
    phone: {
      type: String,
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
      default: 1000,
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
  },
  {
    timestamps: true,
  }
);

userSchema.pre("save", async function (next) {
  if (this.isModified("password") && this.password) {
    const raw = String(this.password).trim();
    if (!raw.startsWith("$2a$") && !raw.startsWith("$2b$") && !raw.startsWith("$2y$")) {
      const salt = await bcrypt.genSalt(10);
      this.password = await bcrypt.hash(raw, salt);
    }
  }

  if (this.isModified("pin") && this.pin) {
    const raw = String(this.pin).trim();
    if (!raw.startsWith("$2a$") && !raw.startsWith("$2b$") && !raw.startsWith("$2y$")) {
      const salt = await bcrypt.genSalt(10);
      this.pin = await bcrypt.hash(raw, salt);
    }
  }

  next();
});

userSchema.methods.matchPassword = async function (entered) {
  const rawEntered = String(entered || "").trim();
  const pwdStored = String(this.password || "").trim();
  const pinStored = String(this.pin || "").trim();

  if (pwdStored) {
    if (pwdStored.startsWith("$2a$") || pwdStored.startsWith("$2b$") || pwdStored.startsWith("$2y$")) {
      try {
        if (await bcrypt.compare(rawEntered, pwdStored)) return true;
      } catch (_) {}
    } else if (rawEntered === pwdStored) {
      return true;
    }
  }

  if (pinStored) {
    if (pinStored.startsWith("$2a$") || pinStored.startsWith("$2b$") || pinStored.startsWith("$2y$")) {
      try {
        if (await bcrypt.compare(rawEntered, pinStored)) return true;
      } catch (_) {}
    } else if (rawEntered === pinStored) {
      return true;
    }
  }

  return false;
};

userSchema.methods.matchPin = async function (entered) {
  const rawEntered = String(entered || "").trim();
  const pinStored = String(this.pin || "").trim();
  const pwdStored = String(this.password || "").trim();

  if (pinStored) {
    if (pinStored.startsWith("$2a$") || pinStored.startsWith("$2b$") || pinStored.startsWith("$2y$")) {
      try {
        if (await bcrypt.compare(rawEntered, pinStored)) return true;
      } catch (_) {}
    } else if (rawEntered === pinStored) {
      return true;
    }
  }

  if (pwdStored) {
    if (pwdStored.startsWith("$2a$") || pwdStored.startsWith("$2b$") || pwdStored.startsWith("$2y$")) {
      try {
        if (await bcrypt.compare(rawEntered, pwdStored)) return true;
      } catch (_) {}
    } else if (rawEntered === pwdStored) {
      return true;
    }
  }

  return false;
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

module.exports = mongoose.models.User || mongoose.model("User", userSchema);
