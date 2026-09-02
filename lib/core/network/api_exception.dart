import 'package:dio/dio.dart';

/// 统一异常类型，供仓储 / 数据源向领域层与 UI 层传播错误。
///
/// 所有 feature 的网络错误都应被转换为 [ApiException]，
/// 这样 UI 层只需要针对一种异常做展示与重试处理。
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  /// 面向用户的错误提示。
  final String message;

  /// HTTP 状态码（非网络类错误时为 null）。
  final int? statusCode;

  /// 原始异常（用于调试日志）。
  final Object? cause;

  /// 将 [DioException] 转换为用户友好的 [ApiException]。
  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException('网络请求超时，请稍后重试', cause: e);
      case DioExceptionType.connectionError:
        return ApiException('网络连接失败，请检查网络设置', cause: e);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return ApiException('请求失败（HTTP $code）', statusCode: code, cause: e);
      case DioExceptionType.badCertificate:
        return ApiException('证书校验失败', cause: e);
      case DioExceptionType.cancel:
        return ApiException('请求已取消', cause: e);
      case DioExceptionType.unknown:
        return ApiException('网络异常，请稍后重试', cause: e);
    }
  }

  @override
  String toString() => 'ApiException(message: $message, statusCode: $statusCode)';
}
