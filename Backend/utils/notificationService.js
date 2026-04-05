/**
 * ECO Wallet — Notification Service
 * Sends both in-app and push notifications via FCM.
 */
const admin = require("../config/firebase");
const Notification = require("../models/Notification");
const User = require("../models/User");

class NotificationService {
  /**
   * Send notification to a specific user.
   * @param {string} user_id 
   * @param {Object} payload { title, message, type, data }
   */
  static async send(user_id, { title, message, type = "system", data = null }) {
    try {
      // 1. Create in-app notification in DB
      const inAppNotif = await Notification.create({
        user_id,
        title,
        message,
        type,
        data,
      });

      // 2. Find user's FCM token
      const user = await User.findOne({ user_id });
      if (user && user.fcmToken) {
        // 3. Send push via FCM
        const messagePayload = {
          token: user.fcmToken,
          notification: {
            title,
            body: message,
          },
          data: data ? { ...data, type } : { type },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              sound: "default",
              clickAction: "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        };

        try {
          await admin.messaging().send(messagePayload);
        } catch (fcmError) {
          console.error("FCM Send Error:", fcmError.message);
          // If token is invalid, clear it
          if (fcmError.code === "messaging/registration-token-not-registered") {
            user.fcmToken = null;
            await user.save();
          }
        }
      }

      return inAppNotif;
    } catch (error) {
      console.error("Notification Service Error:", error.message);
    }
  }

  /**
   * Helper for transaction notifications
   */
  static async sendTransaction(user_id, amount, isCredit = true, details = "") {
    const title = isCredit ? "Money Received! 💰" : "Money Sent! 💸";
    const msg = isCredit 
      ? `You received ₹${amount}. ${details}` 
      : `You sent ₹${amount}. ${details}`;
    
    return await this.send(user_id, {
      title,
      message: msg,
      type: "transaction",
    });
  }
}

const notify = async (user_id, type, title, message, data = null) => {
  return await NotificationService.send(user_id, { title, message, type, data });
};

/**
 * Send notification to ALL users (broadcast).
 * Used for system-wide alerts like bank exhaustion.
 */
const notifyAll = async (type, title, message, data = null) => {
  try {
    const users = await User.find({}).select("user_id").lean();
    const results = await Promise.allSettled(
      users.map((u) =>
        NotificationService.send(u.user_id, { title, message, type, data })
      )
    );
    const sent = results.filter((r) => r.status === "fulfilled").length;
    console.log(`📢 Broadcast notification sent to ${sent}/${users.length} users`);
    return sent;
  } catch (error) {
    console.error("notifyAll Error:", error.message);
  }
};

module.exports = { NotificationService, notify, notifyAll };
