import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FirebaseConfig {
  static const firebaseConfigWeb = FirebaseOptions(
    apiKey: "AIzaSyAnG_z1cSjOiUDRozh4DCFaZhglAuUc-Z4",
    authDomain: "eco-wallet-816c3.firebaseapp.com",
    projectId: "eco-wallet-816c3",
    storageBucket: "eco-wallet-816c3.firebasestorage.app",
    messagingSenderId: "679816423966",
    appId: "1:679816423966:web:eea828bbd24878037d1c0f",
    measurementId: "G-TG01V3834W",
  );

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await Firebase.initializeApp(
      options: kIsWeb ? firebaseConfigWeb : null,
    );

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      await registerToken();
    }

    // Initialize Local Notifications for foreground handling
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  static Future<void> registerToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.registerFcmToken(token);
      }
    } catch (e) {
      debugPrint("FCM Register Error: $e");
    }
  }
}

// Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}
