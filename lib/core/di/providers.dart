import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../storage/local_storage.dart';

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
