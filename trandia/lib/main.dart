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

/// Background handler — must be top-level.
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase init
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[Firebase] ✅ Initialized');
  } catch (e) {
    debugPrint('[Firebase] ❌ $e');
  }

  // 2. Background message handler (must be before runApp)
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  // 3. Init local notifications plugin + channel ONLY.
  //    NO permission request here — Android 13+ needs Activity RESUMED state.
  //    Permission is requested from HomeScreen via requestPermissionAndSyncToken().
  await FcmService.initAndCache();

  // 4. Register foreground message listener BEFORE runApp so no messages
  //    are missed during the login → HomeScreen navigation transition.
  FcmService.startForegroundListener();

  // 5. Token refresh listener
  FcmService.listenForTokenRefresh();

  // 6. Background tap handler
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

  FlutterError.onError = (d) => FlutterError.presentError(d);

  runZonedGuarded(
    () => runApp(const MyApp()),
    (e, st) => debugPrint('[UNCAUGHT] $e\n$st'),
  );
}

void _handleNotificationTap(RemoteMessage message) {
  debugPrint('[FCM] Notification tapped: ${message.data}');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final RemoteMessage? initial =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] App opened from terminated: ${initial.data}');
      _handleNotificationTap(initial);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trandia',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const _SplashRouter(),
      );
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
    final params = getUrlSearchParams();
    if (params.containsKey('token')) {
      await ApiService.saveToken(params['token']!);
      clearUrlSearchParams();
      if (!mounted) return;
      _go(const HomeScreen());
      return;
    }
    try {
      final ok = await AuthService.isLoggedIn();
      if (!mounted) return;
      _go(ok ? const HomeScreen() : const LoginScreen());
    } catch (_) {
      if (!mounted) return;
      _go(const LoginScreen());
    }
  }

  void _go(Widget w) => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
