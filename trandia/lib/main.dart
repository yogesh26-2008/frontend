import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'utils/web_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated firebase_options.dart
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FcmService.listenForTokenRefresh();
  } catch (e) {
    debugPrint('[Firebase] Init failed (non-fatal): $e');
  }

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
    await _requestNotificationPermission();

    // Web Google OAuth redirect — read ?token= from URL
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

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isProvisional) {
        await Permission.notification.request();
      }
    } catch (_) {}
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
