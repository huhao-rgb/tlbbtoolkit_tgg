// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 首页仓储的依赖注入。
///
/// 根据 [AppConstants.useLocalDataSource] 切换本地 / 远程数据源。

@ProviderFor(homeRepository)
final homeRepositoryProvider = HomeRepositoryProvider._();

/// 首页仓储的依赖注入。
///
/// 根据 [AppConstants.useLocalDataSource] 切换本地 / 远程数据源。

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  /// 首页仓储的依赖注入。
  ///
  /// 根据 [AppConstants.useLocalDataSource] 切换本地 / 远程数据源。
  HomeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'fb262a411c3fd09e514377a8912502b6bb96a61e';
