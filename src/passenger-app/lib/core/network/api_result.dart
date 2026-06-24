import 'package:dio/dio.dart';

class ApiResult<T> {
  final T? data;
  final int? code;
  final String? message;
  final bool isSuccess;

  const ApiResult.success(this.data)
      : code = 0,
        message = null,
        isSuccess = true;

  const ApiResult.error(this.message)
      : data = null,
        code = null,
        isSuccess = false;

  static ApiResult<T> fromResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = response.data as Map<String, dynamic>;
    final code = body['code'] as int;
    if (code == 0) {
      final dataJson = body['data'] as Map<String, dynamic>?;
      if (dataJson == null) {
        return ApiResult.success(null as T);
      }
      return ApiResult.success(fromJson(dataJson));
    }
    return ApiResult.error(body['message'] as String? ?? '未知错误');
  }
}
