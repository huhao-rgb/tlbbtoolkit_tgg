// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据目录的缓存介质（原生=文件，Web=SharedPreferences）。
///
/// 文件目录不可用（只读沙盒、单元测试没有 path_provider 插件）时退回
/// SharedPreferences：功能降级为「本次进程可用」，但绝不让上层报错。

@ProviderFor(catalogStorage)
final catalogStorageProvider = CatalogStorageProvider._();

/// 数据目录的缓存介质（原生=文件，Web=SharedPreferences）。
///
/// 文件目录不可用（只读沙盒、单元测试没有 path_provider 插件）时退回
/// SharedPreferences：功能降级为「本次进程可用」，但绝不让上层报错。

final class CatalogStorageProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogStorage>,
          CatalogStorage,
          FutureOr<CatalogStorage>
        >
    with $FutureModifier<CatalogStorage>, $FutureProvider<CatalogStorage> {
  /// 数据目录的缓存介质（原生=文件，Web=SharedPreferences）。
  ///
  /// 文件目录不可用（只读沙盒、单元测试没有 path_provider 插件）时退回
  /// SharedPreferences：功能降级为「本次进程可用」，但绝不让上层报错。
  CatalogStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogStorageHash();

  @$internal
  @override
  $FutureProviderElement<CatalogStorage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogStorage> create(Ref ref) {
    return catalogStorage(ref);
  }
}

String _$catalogStorageHash() => r'b5cbaccfed01c7040c68f7ddd947dcc353aa5105';

/// 远端请求专用 Dio：不挂 LogInterceptor —— 分片有几百 KB，打日志既无用又拖慢。

@ProviderFor(catalogDio)
final catalogDioProvider = CatalogDioProvider._();

/// 远端请求专用 Dio：不挂 LogInterceptor —— 分片有几百 KB，打日志既无用又拖慢。

final class CatalogDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 远端请求专用 Dio：不挂 LogInterceptor —— 分片有几百 KB，打日志既无用又拖慢。
  CatalogDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return catalogDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$catalogDioHash() => r'fb5e99c711f1d929701ade1ef06dfcfd693aec9d';

/// 数据目录仓储。首次读取时会激活上次下载好的待更新数据。
///
/// `CATALOG_BASE_URL` 留空时不构造远端源 —— 完全离线，只用内置数据。

@ProviderFor(catalogRepository)
final catalogRepositoryProvider = CatalogRepositoryProvider._();

/// 数据目录仓储。首次读取时会激活上次下载好的待更新数据。
///
/// `CATALOG_BASE_URL` 留空时不构造远端源 —— 完全离线，只用内置数据。

final class CatalogRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogRepository>,
          CatalogRepository,
          FutureOr<CatalogRepository>
        >
    with
        $FutureModifier<CatalogRepository>,
        $FutureProvider<CatalogRepository> {
  /// 数据目录仓储。首次读取时会激活上次下载好的待更新数据。
  ///
  /// `CATALOG_BASE_URL` 留空时不构造远端源 —— 完全离线，只用内置数据。
  CatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<CatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogRepository> create(Ref ref) {
    return catalogRepository(ref);
  }
}

String _$catalogRepositoryHash() => r'b151f1db489dc34740e67a8b785f5fc036300726';

/// 启动后的后台检查（UI 不需要它的结果，只借它触发一次）。
///
/// 这里必须**吞掉所有异常**：缓存目录不可用（如单元测试没有 path_provider 插件）
/// 不应该让根组件的 Riverpod 作用域出现未处理错误。

@ProviderFor(catalogBootstrap)
final catalogBootstrapProvider = CatalogBootstrapProvider._();

/// 启动后的后台检查（UI 不需要它的结果，只借它触发一次）。
///
/// 这里必须**吞掉所有异常**：缓存目录不可用（如单元测试没有 path_provider 插件）
/// 不应该让根组件的 Riverpod 作用域出现未处理错误。

final class CatalogBootstrapProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogRefreshOutcome>,
          CatalogRefreshOutcome,
          FutureOr<CatalogRefreshOutcome>
        >
    with
        $FutureModifier<CatalogRefreshOutcome>,
        $FutureProvider<CatalogRefreshOutcome> {
  /// 启动后的后台检查（UI 不需要它的结果，只借它触发一次）。
  ///
  /// 这里必须**吞掉所有异常**：缓存目录不可用（如单元测试没有 path_provider 插件）
  /// 不应该让根组件的 Riverpod 作用域出现未处理错误。
  CatalogBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogBootstrapHash();

  @$internal
  @override
  $FutureProviderElement<CatalogRefreshOutcome> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogRefreshOutcome> create(Ref ref) {
    return catalogBootstrap(ref);
  }
}

String _$catalogBootstrapHash() => r'704d9dae77a47d9d7e5ce142e149a5d5571e7b5b';
