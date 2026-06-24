import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ride_hermes_passenger/config/app_config.dart';
import 'package:ride_hermes_passenger/core/network/api_result.dart';

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

  Future<ApiResult<Map<String, dynamic>>> get(String path,
      {Map<String, dynamic>? params}) async {
    final token = await accessToken;
    try {
      final resp = await _dio.get(path,
          queryParameters: params,
          options: Options(headers: _authHeader(token)));
      return _parseResponse(resp);
    } on DioException catch (e) {
      return ApiResult.error(_formatError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(String path,
      {dynamic data}) async {
    final token = await accessToken;
    try {
      final resp = await _dio.post(path,
          data: data, options: Options(headers: _authHeader(token)));
      return _parseResponse(resp);
    } on DioException catch (e) {
      return ApiResult.error(_formatError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> delete(String path) async {
    final token = await accessToken;
    try {
      final resp = await _dio.delete(path,
          options: Options(headers: _authHeader(token)));
      return _parseResponse(resp);
    } on DioException catch (e) {
      return ApiResult.error(_formatError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> put(String path,
      {dynamic data}) async {
    final token = await accessToken;
    try {
      final resp = await _dio.put(path,
          data: data, options: Options(headers: _authHeader(token)));
      return _parseResponse(resp);
    } on DioException catch (e) {
      return ApiResult.error(_formatError(e));
    }
  }

  ApiResult<Map<String, dynamic>> _parseResponse(Response resp) {
    final body = resp.data as Map<String, dynamic>;
    final code = body['code'] as int;
    if (code == 0) {
      return ApiResult.success(body);
    }
    return ApiResult.error(body['message'] as String? ?? '未知错误');
  }

  String _formatError(DioException e) {
    if (e.response != null) {
      final body = e.response!.data;
      if (body is Map && body['message'] != null) {
        return body['message'] as String;
      }
      return '请求失败: ${e.response!.statusCode}';
    }
    return '网络错误: ${e.message}';
  }

  Map<String, String>? _authHeader(String? token) {
    if (token == null) return null;
    return {'Authorization': 'Bearer $token'};
  }
}
