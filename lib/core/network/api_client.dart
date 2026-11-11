import 'package:dio/dio.dart';

import 'package:tlbbtoolkit/core/network/api_exception.dart';

/// [Dio] 实例工厂与统一配置。
///
/// 只负责按用途创建配置好的 [Dio] 实例；实例由使用方（各 feature 的
/// data 层 / 云同步 / 数据目录）自己持有并负责关闭，**不再提供全局共享实例**
/// ——全局 autoDispose 客户端曾导致进行中的请求被 `close()` 打断。
class ApiClient {
  const ApiClient._();

  /// 创建云同步专用的 [Dio]。
  ///
  /// **不挂 LogInterceptor**：云同步是高频静默调用，
  /// 且请求体是整段密文，打日志既无用又吵闹。
  static Dio createSyncDio(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  /// 创建数据目录专用的 [Dio]。
  ///
  /// 与 [createSyncDio] 同理不挂日志；区别是**接收超时更长**——
  /// 分片可达数百 KB，弱网下 15s 容易被误判为失败。
  static Dio createCatalogDio(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  /// 供仓储层统一处理 [DioException]。
  static ApiException toApiException(Object error) {
    if (error is DioException) {
      return ApiException.fromDioException(error);
    }
    return ApiException('网络异常，请稍后重试', cause: error);
  }
}
