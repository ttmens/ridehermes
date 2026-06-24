import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ride_hermes_driver/config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? code;
  const ApiException(this.message, [this.code]);

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        )),
        _storage = const FlutterSecureStorage();

  Future<String?> get accessToken => _storage.read(key: _tokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _tokenKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  /// Login or register — no auth header, returns unwrapped data.
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final resp = await _dio.post('/api/v1/auth/login-or-register', data: {
      'phone': phone,
      'password': password,
      'role': 3, // driver
    });
    return _unwrap(resp);
  }

  /// Authenticated GET — returns unwrapped data.
  Future<Map<String, dynamic>> authGet(String path,
      {Map<String, dynamic>? params}) async {
    final token = await accessToken;
    try {
      final resp = await _dio.get(path,
          queryParameters: params,
          options: Options(headers: _authHeader(token)));
      return _unwrap(resp);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Authenticated POST — returns unwrapped data.
  Future<Map<String, dynamic>> authPost(String path, {dynamic data}) async {
    final token = await accessToken;
    try {
      final resp = await _dio.post(path,
          data: data, options: Options(headers: _authHeader(token)));
      return _unwrap(resp);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Authenticated PUT — returns unwrapped data.
  Future<Map<String, dynamic>> authPut(String path, {dynamic data}) async {
    final token = await accessToken;
    try {
      final resp = await _dio.put(path,
          data: data, options: Options(headers: _authHeader(token)));
      return _unwrap(resp);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, String>? _authHeader(String? token) {
    if (token == null) return null;
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _unwrap(Response resp) {
    final body = resp.data;
    if (body is Map<String, dynamic>) {
      final code = body['code'] as num?;
      final message = body['message'] as String?;
      if (code != null && code.toInt() != 0) {
        throw ApiException(message ?? '请求失败', code.toInt());
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data == null) return {};
    }
    return {};
  }

  ApiException _mapError(DioException e) {
    final msg = e.response?.data is Map
        ? (e.response!.data['message'] as String?) ?? '请求失败'
        : '网络错误';
    return ApiException(msg, e.response?.statusCode);
  }
}
