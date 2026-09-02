import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_exception.dart';

/// [Dio] 实例工厂与统一配置。
///
/// 只负责创建配置完整的 [Dio] 实例，实例本身通过
/// `core/di/providers.dart` 中的 [dioProvider] 提供给各 feature。
class ApiClient {
  const ApiClient._();

  /// 创建配置完成的 [Dio] 实例。
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll(<Interceptor>[
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          // 统一走 Logger 或直接输出
          // ignore: avoid_print
          print(object);
        },
      ),
    ]);

    return dio;
  }

  /// 供仓储层统一处理 [DioException]。
  static ApiException toApiException(Object error) {
    if (error is DioException) {
      return ApiException.fromDioException(error);
    }
    return ApiException('网络异常，请稍后重试', cause: error);
  }
}
