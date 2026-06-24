import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/models/user.dart';
import 'package:ride_hermes_passenger/services/api_service.dart';
import 'package:ride_hermes_passenger/core/location/location_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final locationServiceProvider = Provider<LocationService>((ref) {
  final svc = LocationService();
  ref.onDispose(() => svc.dispose());
  return svc;
});

class AuthState {
  final bool isLoggedIn;
  final User? user;
  final AuthTokens? tokens;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.tokens,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    User? user,
    AuthTokens? tokens,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<void> init() async {
    final token = await _api.accessToken;
    if (token != null) {
      // Token exists but we need to validate and fetch user profile
      try {
        final result = await _api.get('/api/v1/passenger/user/profile');
        if (result.isSuccess && result.data != null) {
          final userData = result.data!['data'] as Map<String, dynamic>?;
          if (userData != null) {
            final user = User.fromJson(userData);
            state = AuthState(
              isLoggedIn: true,
              user: user,
              isInitialized: true,
            );
            return;
          }
        }
      } catch (_) {
        // Token invalid or expired, clear it
        await _api.clearTokens();
      }
    }
    state = state.copyWith(isInitialized: true);
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.post('/api/v1/auth/login-or-register', data: {
        'phone': phone,
        'password': password,
        'role': 2, // passenger
      });

      if (result.isSuccess && result.data != null) {
        final body = result.data!;
        final data = body['data'] as Map<String, dynamic>;
        final tokens = AuthTokens.fromJson(data);
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          await _api.saveTokens(tokens.accessToken, tokens.refreshToken);
          final user = User.fromJson(userData);
          state = AuthState(
            isLoggedIn: true,
            user: user,
            tokens: tokens,
            isLoading: false,
            isInitialized: true,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message ?? '登录失败',
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '登录失败: $e',
        isInitialized: true,
      );
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = const AuthState(isLoggedIn: false, isInitialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});
