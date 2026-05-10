import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'fcm_service.dart';
import '../utils/web_utils.dart';

const String _webClientId =
    '461111861227-6lp4k1p2iuoe50sl46bvpdp2d6smvola.apps.googleusercontent.com';

const String _backendUrl = 'https://web-production-c105c.up.railway.app';

GoogleSignIn? _googleSignInInstance;
GoogleSignIn get _googleSignIn {
  _googleSignInInstance ??= GoogleSignIn(serverClientId: _webClientId);
  return _googleSignInInstance!;
}

class AuthService {
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final fcmToken = await FcmService.getCachedToken();

    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final data = await ApiService.post('/auth/login', body);
    await ApiService.saveToken(data['access_token'] as String);

    final user = data['user'] as Map<String, dynamic>?;
    final firstName = user?['name']?.toString().split(' ').first ?? 'there';

    // ── Show notification ALWAYS — do not gate on permission check ──────
    // Permission is handled by HomeScreen after Activity is RESUMED.
    // We fire-and-forget here — if permission not yet granted, Android
    // will silently drop the notification (no crash). Once HomeScreen
    // runs requestPermissionAndSyncToken(), future notifications work.
    _showWelcomeNotification(
      title: "Welcome back, $firstName ✦",
      body: "Great to have you back. Your feed is right where you left it.",
    );

    return data;
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final fcmToken = await FcmService.getCachedToken();

    final body = <String, dynamic>{
      'name': name,
      'username': username,
      'email': email,
      'password': password,
    };
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final data = await ApiService.post('/auth/signup', body);
    await ApiService.saveToken(data['access_token'] as String);

    final firstName = name.split(' ').first;

    _showWelcomeNotification(
      title: "Welcome to Trandia ✦",
      body: "Hi $firstName, you're all set. Explore conversations and connect with people.",
    );

    return data;
  }

  // ── Fire-and-forget welcome notification ─────────────────────────────────
  // Delay 1.5s so the user sees the HomeScreen before the notification
  // pops up. No await — login/signup returns immediately.
  static void _showWelcomeNotification({
    required String title,
    required String body,
  }) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      FcmService.showNotification(title: title, body: body);
    });
  }

  static Future<Map<String, dynamic>?> loginWithGoogle() async {
    if (kIsWeb) {
      final origin = getWindowOrigin();
      final redirectUrl =
          '$_backendUrl/auth/google/web?app_origin=${Uri.encodeComponent(origin)}';
      launchWebUrl(redirectUrl);
      return null;
    }

    final account = await _googleSignIn.signIn();
    if (account == null) throw const ApiException('Google sign-in cancelled');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const ApiException('Could not get Google ID token from device.');
    }

    final fcmToken = await FcmService.getCachedToken();

    final body = <String, dynamic>{'id_token': idToken};
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final data = await ApiService.post('/auth/google/verify', body);
    await ApiService.saveToken(data['access_token'] as String);

    final user = data['user'] as Map<String, dynamic>?;
    final firstName = user?['name']?.toString().split(' ').first ?? 'there';

    _showWelcomeNotification(
      title: "Welcome to Trandia ✦",
      body: "Hi $firstName, you're all set. Explore conversations and connect with people.",
    );

    return data;
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return false;
      if (_isTokenExpired(token)) {
        await ApiService.clearToken();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final payloadMap =
          jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map;
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSecs >= (exp - 30);
    } catch (_) {
      return true;
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.clearToken();
    } catch (_) {}
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }
}
