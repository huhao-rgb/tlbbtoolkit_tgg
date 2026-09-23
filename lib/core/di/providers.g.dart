// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局 [Dio] 实例，供各 feature 的网络数据源使用。

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// 全局 [Dio] 实例，供各 feature 的网络数据源使用。

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 全局 [Dio] 实例，供各 feature 的网络数据源使用。
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'8f5356bb2e1ca6ee59b5128ea27cd0121316aa98';

/// 全局 [SharedPreferences] 实例。
///
/// 在 `main()` 中通过 `overrideWithValue` 注入真实实例：
/// ```dart
/// ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
/// )
/// ```

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// 全局 [SharedPreferences] 实例。
///
/// 在 `main()` 中通过 `overrideWithValue` 注入真实实例：
/// ```dart
/// ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
/// )
/// ```

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// 全局 [SharedPreferences] 实例。
  ///
  /// 在 `main()` 中通过 `overrideWithValue` 注入真实实例：
  /// ```dart
  /// ProviderScope(
  ///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  /// )
  /// ```
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'edc723b0bf7f57b4bfbc3e7884975aed5516579f';

/// 本地 KV 存储封装，feature 仓储层通过它读写本地数据。

@ProviderFor(localStorage)
final localStorageProvider = LocalStorageProvider._();

/// 本地 KV 存储封装，feature 仓储层通过它读写本地数据。

final class LocalStorageProvider
    extends $FunctionalProvider<LocalStorage, LocalStorage, LocalStorage>
    with $Provider<LocalStorage> {
  /// 本地 KV 存储封装，feature 仓储层通过它读写本地数据。
  LocalStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localStorageHash();

  @$internal
  @override
  $ProviderElement<LocalStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalStorage create(Ref ref) {
    return localStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalStorage>(value),
    );
  }
}

String _$localStorageHash() => r'5c3fbac58b511e27789874d27914836b4215318d';

/// 应用包信息（应用名 / 版本号 / 构建号），运行时由 `package_info_plus`
/// 从平台侧读取。
///
/// 版本号的唯一事实源是 `pubspec.yaml` 的 `version:` 字段（如 `1.0.3+4`），
/// 由构建产物带到各平台，**代码里不要再写死版本号**。
///
/// 读取是异步的，且可能失败（如单元测试环境没有插件实现），
/// 调用方需按 `AsyncValue` 处理 loading / error。

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

/// 应用包信息（应用名 / 版本号 / 构建号），运行时由 `package_info_plus`
/// 从平台侧读取。
///
/// 版本号的唯一事实源是 `pubspec.yaml` 的 `version:` 字段（如 `1.0.3+4`），
/// 由构建产物带到各平台，**代码里不要再写死版本号**。
///
/// 读取是异步的，且可能失败（如单元测试环境没有插件实现），
/// 调用方需按 `AsyncValue` 处理 loading / error。

final class PackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  /// 应用包信息（应用名 / 版本号 / 构建号），运行时由 `package_info_plus`
  /// 从平台侧读取。
  ///
  /// 版本号的唯一事实源是 `pubspec.yaml` 的 `version:` 字段（如 `1.0.3+4`），
  /// 由构建产物带到各平台，**代码里不要再写死版本号**。
  ///
  /// 读取是异步的，且可能失败（如单元测试环境没有插件实现），
  /// 调用方需按 `AsyncValue` 处理 loading / error。
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'f1c17d5174896e536210506ee5ade32f9766a6b9';
