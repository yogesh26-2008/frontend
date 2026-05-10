import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// FIX: New channel ID — Android caches channel settings permanently.
// Old 'trandia_welcome' channel had wrong importance level cached from
// previous installs. New ID forces Android to create a fresh channel.
const _kChannelId   = 'trandia_ch1';
const _kChannelName = 'Trandia';
const _kChannelDesc = 'Trandia notifications';
const _kTokenKey    = 'fcm_token';
const _kJwtKey      = 'auth_token';
const _kBackendUrl  = 'https://web-production-c105c.up.railway.app';

final _localNotif = FlutterLocalNotificationsPlugin();
bool _channelReady       = false;
bool _listenerRegistered = false; // FIX: prevents duplicate onMessage subscriptions

class FcmService {

  // ── Init (call once in main before runApp) ────────────────────────────────
  static Future<void> initAndCache() async {
    if (kIsWeb) return;
    await _setupChannel();
    await _fetchAndCacheToken();
  }

  static Future<void> _setupChannel() async {
    try {
      // Create Android notification channel
      const channel = AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: _kChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidImpl = _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(channel);
        debugPrint('[FCM] ✅ Channel created: $_kChannelId');
      } else {
        debugPrint('[FCM] ⚠️ AndroidFlutterLocalNotificationsPlugin is null');
      }

      // Initialize flutter_local_notifications
      final bool? initResult = await _localNotif.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      debugPrint('[FCM] ✅ LocalNotifications init: $initResult');
      _channelReady = true;
    } catch (e, st) {
      debugPrint('[FCM] ❌ _setupChannel error: $e\n$st');
    }
  }

  // ── Fetch + cache FCM token ────────────────────────────────────────────────
  static Future<void> _fetchAndCacheToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS: show notification banner even when app is open
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] ❌ Notification permission denied by user');
        return;
      }

      final newToken = await messaging.getToken();
      if (newToken == null || newToken.isEmpty) {
        debugPrint('[FCM] ⚠️ Token null — check google-services.json');
        return;
      }
      debugPrint('[FCM] ✅ Token: ${newToken.substring(0, 25)}...');

      final prefs       = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_kTokenKey);

      await prefs.setString(_kTokenKey, newToken);

      if (cachedToken != newToken) {
        debugPrint('[FCM] 🆕 Token changed — syncing with backend');
        await _syncTokenWithBackend(newToken, prefs);
      }
    } catch (e, st) {
      debugPrint('[FCM] ❌ _fetchAndCacheToken error: $e\n$st');
    }
  }

  // ── Foreground listener (call from HomeScreen.initState) ──────────────────
  // FIX: Guard with _listenerRegistered so multiple HomeScreen rebuilds
  // don't register multiple subscriptions to onMessage.
  static void startForegroundListener() {
    if (_listenerRegistered) {
      debugPrint('[FCM] Foreground listener already registered — skip');
      return;
    }
    _listenerRegistered = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM] 📩 onMessage: title=${message.notification?.title}');
      debugPrint('[FCM]    data=${message.data}');
      await _showNotification(
        title: message.notification?.title ?? message.data['title'] ?? 'Trandia',
        body:  message.notification?.body  ?? message.data['body']  ?? '',
      );
    });

    debugPrint('[FCM] ✅ Foreground listener registered');
  }

  // ── Show local notification ───────────────────────────────────────────────
  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    if (!_channelReady) {
      debugPrint('[FCM] ⚠️ Channel not ready — retrying setup');
      await _setupChannel();
    }

    try {
      debugPrint('[FCM] Calling localNotif.show(): "$title"');
      await _localNotif.show(
        42, // Fixed ID — same notification replaces previous
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            _kChannelName,
            channelDescription: _kChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF00C853),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('[FCM] ✅ localNotif.show() completed');
    } catch (e, st) {
      debugPrint('[FCM] ❌ localNotif.show() FAILED: $e\n$st');
    }
  }

  // ── Token refresh listener ────────────────────────────────────────────────
  static void listenForTokenRefresh() {
    if (kIsWeb) return;
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, newToken);
        debugPrint('[FCM] 🔄 Token refreshed: ${newToken.substring(0, 20)}...');
        await _syncTokenWithBackend(newToken, prefs);
      });
    } catch (e) {
      debugPrint('[FCM] listenForTokenRefresh error: $e');
    }
  }

  // ── Sync token with backend ───────────────────────────────────────────────
  static Future<void> _syncTokenWithBackend(
      String token, SharedPreferences prefs) async {
    try {
      final jwt = prefs.getString(_kJwtKey);
      if (jwt == null) {
        debugPrint('[FCM] Not logged in — skip backend sync');
        return;
      }
      final resp = await http.put(
        Uri.parse('$_kBackendUrl/users/me/fcm-token'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: '{"fcm_token": "$token"}',
      ).timeout(const Duration(seconds: 10));
      debugPrint('[FCM] Backend sync: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] _syncTokenWithBackend error (non-fatal): $e');
    }
  }

  // ── Get cached token (used during login/signup) ───────────────────────────
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
}
