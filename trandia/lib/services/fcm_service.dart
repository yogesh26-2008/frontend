import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kChannelId   = 'trandia_welcome';
const _kChannelName = 'Trandia Notifications';
const _kChannelDesc = 'Welcome and activity notifications from Trandia';
const _kTokenKey    = 'fcm_token';

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  _kChannelId,
  _kChannelName,
  description: _kChannelDesc,
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

class FcmService {
  static Future<void> initAndCache() async {
    if (kIsWeb) return;
    await _setupLocalNotifications();
    await _refreshToken(); // Always fetch fresh token — don't rely on stale cache
    _listenForeground();
  }

  static Future<void> _setupLocalNotifications() async {
    try {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _localNotif.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      debugPrint('[FCM] ✅ Notification channel ready: $_kChannelId');
    } catch (e) {
      debugPrint('[FCM] _setupLocalNotifications error: $e');
    }
  }

  /// Always fetches a fresh token from FCM and saves it.
  /// FCM returns the same token if it hasn't changed — no extra cost.
  static Future<void> _refreshToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permission denied');
        return;
      }

      // Delete stale token first — forces FCM to issue a fresh one
      // This is critical after package name / app reinstall changes
      await messaging.deleteToken();
      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, token);
        debugPrint('[FCM] ✅ Fresh token cached: ${token.substring(0, 25)}...');
      } else {
        debugPrint('[FCM] ⚠️ Token is null — check google-services.json package name');
      }
    } catch (e) {
      debugPrint('[FCM] _refreshToken error: $e');
    }
  }

  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      debugPrint('[FCM] 📩 Foreground: ${notification.title}');

      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            _kChannelName,
            channelDescription: _kChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF00C853),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });
  }

  static Future<String?> getCachedToken() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kTokenKey);
      debugPrint('[FCM] getCachedToken → '
          '${token != null ? "${token.substring(0, 20)}..." : "NULL ⚠️"}');
      return token;
    } catch (e) {
      debugPrint('[FCM] getCachedToken error: $e');
      return null;
    }
  }

  static void listenForTokenRefresh() {
    if (kIsWeb) return;
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, newToken);
        debugPrint('[FCM] 🔄 Token refreshed and cached');
      });
    } catch (e) {
      debugPrint('[FCM] listenForTokenRefresh error: $e');
    }
  }
}
