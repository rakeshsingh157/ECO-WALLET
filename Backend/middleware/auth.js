const jwt = require("jsonwebtoken");
const User = require("../models/User");

const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: "Not authorized - no token provided",
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findOne({ user_id: decoded.user_id }).select(
      "-password -pin"
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Not authorized - user not found",
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: "Not authorized - invalid or expired token",
    });
  }
};

const requireAdmin = (req, res, next) => {
  if (req.user && req.user.role === "admin") {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: "Forbidden - admin access required",
  });
};

const generateTokens = (user_id, role) => {
  const accessToken = jwt.sign(
    { user_id, role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRY || "30d" }
  );

  const refreshToken = jwt.sign(
    { user_id, role, type: "refresh" },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRY || "90d" }
  );

  const backupRefreshToken = jwt.sign(
    { user_id, role, type: "backup_refresh" },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_BACKUP_REFRESH_EXPIRY || "365d" }
  );

  return { accessToken, refreshToken, backupRefreshToken };
};

module.exports = { protect, requireAdmin, generateTokens };
