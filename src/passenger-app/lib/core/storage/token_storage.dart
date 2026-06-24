import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';

  final FlutterSecureStorage _storage;

  TokenStorage() : _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserInfo({
    required int userId,
    required int role,
  }) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _roleKey, value: role.toString());
  }

  Future<int?> get userId async {
    final v = await _storage.read(key: _userIdKey);
    return v != null ? int.tryParse(v) : null;
  }

  Future<int?> get role async {
    final v = await _storage.read(key: _roleKey);
    return v != null ? int.tryParse(v) : null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleKey);
  }

  Future<bool> get isLoggedIn async => (await getAccessToken()) != null;
}
