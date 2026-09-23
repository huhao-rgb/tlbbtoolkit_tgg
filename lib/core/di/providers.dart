import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/network/api_client.dart';
import 'package:tlbbtoolkit/core/storage/local_storage.dart';

part 'providers.g.dart';

/// 全局 [Dio] 实例，供各 feature 的网络数据源使用。
@riverpod
Dio dio(Ref ref) {
  final dio = ApiClient.createDio();
  ref.onDispose(dio.close);
  return dio;
}

/// 全局 [SharedPreferences] 实例。
///
/// 在 `main()` 中通过 `overrideWithValue` 注入真实实例：
/// ```dart
/// ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
/// )
/// ```
@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider 必须在 main() 中 override 注入',
  );
}

/// 本地 KV 存储封装，feature 仓储层通过它读写本地数据。
@riverpod
LocalStorage localStorage(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
}

/// 应用包信息（应用名 / 版本号 / 构建号），运行时由 `package_info_plus`
/// 从平台侧读取。
///
/// 版本号的唯一事实源是 `pubspec.yaml` 的 `version:` 字段（如 `1.0.3+4`），
/// 由构建产物带到各平台，**代码里不要再写死版本号**。
///
/// 读取是异步的，且可能失败（如单元测试环境没有插件实现），
/// 调用方需按 `AsyncValue` 处理 loading / error。
@riverpod
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
