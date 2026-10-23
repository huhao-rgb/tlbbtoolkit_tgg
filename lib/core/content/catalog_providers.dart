import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/constants/app_constants.dart';
import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_remote_source.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/core/content/catalog_storage.dart';
import 'package:tlbbtoolkit/core/content/catalog_storage_factory.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/core/network/api_client.dart';
import 'package:tlbbtoolkit/core/utils/logger.dart';

part 'catalog_providers.g.dart';

/// 数据目录的缓存介质（原生=文件，Web=SharedPreferences）。
///
/// 文件目录不可用（只读沙盒、单元测试没有 path_provider 插件）时退回
/// SharedPreferences：功能降级为「本次进程可用」，但绝不让上层报错。
@Riverpod(keepAlive: true)
Future<CatalogStorage> catalogStorage(Ref ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  try {
    return await openCatalogStorage(prefs: prefs);
  } catch (e, s) {
    Logger.instance.error('Catalog', '文件缓存不可用，退回 SharedPreferences: $e', s);
    return PrefsCatalogStorage(prefs);
  }
}

/// 远端请求专用 Dio：不挂 LogInterceptor —— 分片有几百 KB，打日志既无用又拖慢。
@Riverpod(keepAlive: true)
Dio catalogDio(Ref ref) {
  final dio = ApiClient.createCatalogDio(AppConstants.catalogBaseUrl);
  ref.onDispose(dio.close);
  return dio;
}

/// 数据目录仓储。首次读取时会激活上次下载好的待更新数据。
///
/// `CATALOG_BASE_URL` 留空时不构造远端源 —— 完全离线，只用内置数据。
@Riverpod(keepAlive: true)
Future<CatalogRepository> catalogRepository(Ref ref) async {
  final storage = await ref.watch(catalogStorageProvider.future);
  final baseUrl = AppConstants.catalogBaseUrl;
  final cache = CatalogCache(storage);

  final repository = CatalogRepository(
    cache: cache,
    bundle: rootBundle,
    remote: baseUrl.isEmpty
        ? null
        : CatalogRemoteSource(
            ref.watch(catalogDioProvider),
            baseUrl: baseUrl,
            pathPrefix: AppConstants.catalogPath,
          ),
  );
  await repository.init();
  return repository;
}

/// 启动后的后台检查（UI 不需要它的结果，只借它触发一次）。
///
/// 这里必须**吞掉所有异常**：缓存目录不可用（如单元测试没有 path_provider 插件）
/// 不应该让根组件的 Riverpod 作用域出现未处理错误。
@Riverpod(keepAlive: true)
Future<CatalogRefreshOutcome> catalogBootstrap(Ref ref) async {
  try {
    final repository = await ref.watch(catalogRepositoryProvider.future);
    return await repository.refresh();
  } catch (e, s) {
    Logger.instance.error('Catalog', '启动检查失败（已降级到内置数据）: $e', s);
    return CatalogRefreshOutcome.failed;
  }
}
