import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Represents the current auth session state.
class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final bool isLoading;

  const AuthState({
    required this.isLoggedIn,
    this.userId,
    this.isLoading = false,
  });

  const AuthState.initial() : isLoggedIn = false, userId = null, isLoading = true;

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// StateNotifier that manages auth session.
/// This replaces direct calls to AuthService.isLoggedIn() scattered
/// across the app — state lives here, screens just read it.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await AuthService.isLoggedIn();
    final userId = loggedIn ? await AuthService.getUserId() : null;
    state = AuthState(isLoggedIn: loggedIn, userId: userId, isLoading: false);
  }

  /// Call after a successful login / signup to update state.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final loggedIn = await AuthService.isLoggedIn();
    final userId = loggedIn ? await AuthService.getUserId() : null;
    state = AuthState(isLoggedIn: loggedIn, userId: userId, isLoading: false);
  }

  /// Call after logout.
  void clear() {
    state = const AuthState(isLoggedIn: false, userId: null, isLoading: false);
  }
}

/// Global provider — read anywhere inside ProviderScope.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
