import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/models/user.dart';
import 'package:ride_hermes_driver/services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

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
    if (state.isInitialized) return;
    try {
      final accessToken = await _api.accessToken;
      final refreshToken = await _api.refreshToken;
      if (accessToken == null || refreshToken == null) {
        state = state.copyWith(isInitialized: true);
        return;
      }

      final data = await _api.authGet('/api/v1/driver/user/profile');
      final userJson = data['user'] ?? data;
      final user = userJson is Map<String, dynamic>
          ? User.fromJson(userJson)
          : null;

      state = AuthState(
        isLoggedIn: true,
        user: user,
        tokens: AuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
        isInitialized: true,
      );
    } catch (_) {
      await _api.clearTokens();
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(phone, password);
      final tokens = AuthTokens.fromJson(data);
      final userJson = data['user'];
      final user = userJson is Map<String, dynamic>
          ? User.fromJson(userJson)
          : null;
      await _api.saveTokens(tokens.accessToken, tokens.refreshToken);
      state = AuthState(
        isLoggedIn: true,
        user: user,
        tokens: tokens,
        isInitialized: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '登录失败: $e');
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = AuthState(isLoggedIn: false, isInitialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});
