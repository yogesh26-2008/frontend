import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'utils/web_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Catch Flutter framework errors (widget build errors, layout overflows,
  // etc.) and log them. In production, wire this to Sentry or similar.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // FIX: runZonedGuarded catches uncaught errors in async zones — timers,
  // Futures that nobody awaited, WebSocket callbacks, etc. Without this an
  // unhandled async exception shows a black screen in release mode with no
  // indication of what went wrong.
  runZonedGuarded(
    () => runApp(const MyApp()),
    (Object error, StackTrace stack) {
      debugPrint('[UNCAUGHT] $error\n$stack');
      // TODO: Sentry.captureException(error, stackTrace: stack);
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
    // addPostFrameCallback ensures Navigator is fully ready before we attempt
    // any navigation. Without this, Navigator.pushReplacement can throw a
    // silent exception in release mode (no red screen — app just closes).
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await _requestNotificationPermission();

    // ── Web Google OAuth redirect ────────────────────────────────────────────
    // After Google OAuth, the backend redirects back to:
    //   /?token=JWT&user=...&message=...
    // On web, the Flutter app reloads at this URL. We read the params here,
    // save the token to SharedPreferences, clear the URL, then navigate home.
    // On Android/iOS the stub returns {}, so this block is always skipped.
    final params = getUrlSearchParams();
    if (params.containsKey('token')) {
      final token = params['token']!;
      await ApiService.saveToken(token);
      clearUrlSearchParams(); // remove ?token=... from browser address bar
      if (!mounted) return;
      _navigateTo(const HomeScreen());
      return;
    }

    // ── Normal startup ───────────────────────────────────────────────────────
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
    } catch (_) {
      // Permission request failure must never block app startup
    }
  }

  void _navigateTo(Widget screen, {String? error}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
