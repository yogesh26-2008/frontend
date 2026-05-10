import 'dart:async';
import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kChannelId   = 'trandia_ch2';
const _kChannelName = 'Trandia';
const _kChannelDesc = 'Trandia notifications';
const _kTokenKey    = 'fcm_token';
const _kJwtKey      = 'auth_token';
const _kBackendUrl  = 'https://web-production-c105c.up.railway.app';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _initialized    = false;
bool _listenerActive = false;

class FcmService {

  // ── Step 1: Call from main() before runApp ───────────────────────────────
  // ONLY initialises the local-notification plugin and channel.
  // Does NOT request any permission here — before runApp() the Android
  // Activity is NOT in RESUMED state, so permission dialogs silently fail
  // on Android 13+ (API 33). Permission is requested later from
  // HomeScreen via requestPermissionAndSyncToken().
  static Future<void> initAndCache() async {
    if (kIsWeb) return;
    await _initLocalNotifications();
    await _fetchTokenSilently();
  }

  // ── Local notifications + Android channel setup ──────────────────────────
  static Future<void> _initLocalNotifications() async {
    if (_initialized) return;
    try {
      final bool? ok = await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse r) {
          debugPrint('[FCM] Notification tapped: ${r.payload}');
        },
      );

      _initialized = ok != false;
      debugPrint('[FCM] LocalNotifications init: $ok | _initialized=$_initialized');

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Delete old channel first so Android applies fresh Importance.max.
        // Android permanently caches channel settings once created —
        // deleting ensures heads-up banners work correctly.
        try {
          await androidPlugin.deleteNotificationChannel(_kChannelId);
          debugPrint('[FCM] Old channel deleted');
        } catch (_) {}

        const channel = AndroidNotificationChannel(
          _kChannelId,
          _kChannelName,
          description: _kChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF00C853),
        );

        await androidPlugin.createNotificationChannel(channel);
        debugPrint('[FCM] ✅ Channel created: $_kChannelId Importance.max');
      }
    } catch (e, st) {
      debugPrint('[FCM] ❌ _initLocalNotifications: $e\n$st');
    }
  }

  // ── Silent token read from cache (no permission request) ─────────────────
  static Future<void> _fetchTokenSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kTokenKey);
      debugPrint('[FCM] Cached token: ${cached != null ? "${cached.substring(0, 20)}..." : "none"}');
    } catch (e) {
      debugPrint('[FCM] _fetchTokenSilently error: $e');
    }
  }

  // ── MAIN permission + token sync ─────────────────────────────────────────
  // Call from HomeScreen.initState() via addPostFrameCallback.
  // Activity is fully RESUMED here — dialog shows correctly on Android 13+.
  static Future<void> requestPermissionAndSyncToken() async {
    if (kIsWeb) return;
    try {
      final msg = FirebaseMessaging.instance;

      // Request FCM permission (covers POST_NOTIFICATIONS on Android 13+)
      final settings = await msg.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
      debugPrint('[FCM] FCM Permission: ${settings.authorizationStatus}');

      // iOS foreground display options
      await msg.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] ❌ FCM permission denied by user');
        return;
      }

      // Get FCM token
      final token = await msg.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] ⚠️ Token is null');
        return;
      }
      debugPrint('[FCM] ✅ Token: ${token.substring(0, 20)}...');

      // Cache token
      final prefs = await SharedPreferences.getInstance();
      final old   = prefs.getString(_kTokenKey);
      await prefs.setString(_kTokenKey, token);

      // Sync with backend only if token changed
      if (old != token) {
        debugPrint('[FCM] Token changed — syncing with backend');
        await _syncToken(token, prefs);
      }
    } catch (e, st) {
      debugPrint('[FCM] ❌ requestPermissionAndSyncToken: $e\n$st');
    }
  }

  // ── Android 13+ local notification permission (backup check) ────────────
  static Future<bool> requestLocalPermissionIfNeeded() async {
    if (kIsWeb) return false;
    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? granted =
            await androidPlugin.requestNotificationsPermission();
        debugPrint('[FCM] Local notification permission: $granted');
        return granted ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('[FCM] requestLocalPermissionIfNeeded error: $e');
      return true;
    }
  }

  // ── Foreground message listener ──────────────────────────────────────────
  static void startForegroundListener() {
    if (_listenerActive) {
      debugPrint('[FCM] Listener already active — skip');
      return;
    }
    _listenerActive = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      debugPrint('[FCM] 📩 onMessage: ${msg.notification?.title}');

      if (msg.data['type'] == 'welcome') {
        debugPrint('[FCM] Ignoring backend welcome push (shown locally).');
        return;
      }

      final title = msg.notification?.title
          ?? msg.data['title'] as String?
          ?? 'Trandia';
      final body  = msg.notification?.body
          ?? msg.data['body'] as String?
          ?? '';

      await showNotification(title: title, body: body);
    });

    debugPrint('[FCM] ✅ onMessage listener registered');
  }

  // ── Show notification ────────────────────────────────────────────────────
  static Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    id ??= DateTime.now().millisecondsSinceEpoch % 100000;

    if (!_initialized) {
      debugPrint('[FCM] Not initialized — re-initializing...');
      await _initLocalNotifications();
    }

    debugPrint('[FCM] 🔔 Showing: "$title"');

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            _kChannelName,
            channelDescription: _kChannelDesc,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.message,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );
      debugPrint('[FCM] ✅ Notification displayed');
    } catch (e, st) {
      debugPrint('[FCM] ❌ show() failed: $e\n$st');
    }
  }

  // ── Token refresh listener ───────────────────────────────────────────────
  static void listenForTokenRefresh() {
    if (kIsWeb) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      debugPrint('[FCM] 🔄 Token refreshed');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, token);
      await _syncToken(token, prefs);
    });
  }

  // ── Sync token with backend ──────────────────────────────────────────────
  static Future<void> _syncToken(String token, SharedPreferences prefs) async {
    try {
      final jwt = prefs.getString(_kJwtKey);
      if (jwt == null) return;
      final r = await http.put(
        Uri.parse('$_kBackendUrl/users/me/fcm-token'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: '{"fcm_token": "$token"}',
      ).timeout(const Duration(seconds: 10));
      debugPrint('[FCM] Backend sync: ${r.statusCode}');
    } catch (e) {
      debugPrint('[FCM] _syncToken error: $e');
    }
  }

  // ── Get cached token (used during login/signup) ──────────────────────────
  static Future<String?> getCachedToken() async {
    if (kIsWeb) return null;
    try {
      // Try fresh token first
      final fresh = await FirebaseMessaging.instance.getToken();
      if (fresh != null && fresh.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, fresh);
        debugPrint('[FCM] getCachedToken (fresh): ${fresh.substring(0, 20)}...');
        return fresh;
      }
    } catch (_) {}
    // Fallback to cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_kTokenKey);
      debugPrint('[FCM] getCachedToken (cached): ${t != null ? "${t.substring(0, 20)}..." : "NULL"}');
      return t;
    } catch (e) {
      return null;
    }
  }
}
