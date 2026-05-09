import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles FCM token fetching, caching, and refresh listening.
/// All methods are safe to call — they never throw, just return null on failure.
class FcmService {
  static const _kTokenKey = 'fcm_token';

  /// Get the FCM token for this device.
  /// - Requests permission if not already granted
  /// - Caches the token in SharedPreferences
  /// - Returns null if permission denied or Firebase unavailable
  static Future<String?> getToken() async {
    if (kIsWeb) return null; // FCM tokens not used on web

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (needed on iOS; on Android 13+ also needed)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permission denied — notifications disabled');
        return null;
      }

      final token = await messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, token);
        debugPrint('[FCM] Token fetched: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken failed (non-fatal): $e');
      return null;
    }
  }

  /// Listen for token refreshes and update the cached value.
  /// Call once from main() after Firebase.initializeApp().
  static void listenForTokenRefresh() {
    if (kIsWeb) return;
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, newToken);
        debugPrint('[FCM] Token refreshed: ${newToken.substring(0, 20)}...');
        // TODO: send newToken to backend → PUT /users/me/fcm-token
      });
    } catch (e) {
      debugPrint('[FCM] listenForTokenRefresh failed (non-fatal): $e');
    }
  }
}
