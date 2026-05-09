import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'utils/web_utils.dart';

/// Background message handler — must be a top-level function.
/// Called when a notification arrives while the app is terminated or in background.
/// On Android this runs in a separate isolate — keep it minimal.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized even in background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] ✅ Initialized');
  } catch (e) {
    debugPrint('[Firebase] ❌ Init failed: $e');
  }

  // Step 2: Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Step 3: Create notification channel + fetch FCM token + setup foreground handler
  await FcmService.initAndCache();

  // Step 4: Listen for token refreshes
  FcmService.listenForTokenRefresh();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () => runApp(const MyApp()),
    (Object error, StackTrace stack) {
      debugPrint('[UNCAUGHT] $error\n$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trandia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    // Web Google OAuth redirect
    final params = getUrlSearchParams();
    if (params.containsKey('token')) {
      final token = params['token']!;
      await ApiService.saveToken(token);
      clearUrlSearchParams();
      if (!mounted) return;
      _navigateTo(const HomeScreen());
      return;
    }

    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!mounted) return;
      _navigateTo(loggedIn ? const HomeScreen() : const LoginScreen());
    } catch (e) {
      if (!mounted) return;
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
