import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.messageId}');
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] Foreground: ${msg.notification?.title}');
    });
  }

  static Future<String?> getToken() => _fcm.getToken();
}
