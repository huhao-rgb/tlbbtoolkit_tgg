// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 目录数据的版本号：同步成功后自增，用来让所有 catalog provider 重建。
///
/// 放在 core 而不是各 feature：feature 之间禁止互相 import，而「谁也不知道
/// 有哪些 feature 依赖目录」，用一个自增信号解耦。

@ProviderFor(CatalogRevision)
final catalogRevisionProvider = CatalogRevisionProvider._();

/// 目录数据的版本号：同步成功后自增，用来让所有 catalog provider 重建。
///
/// 放在 core 而不是各 feature：feature 之间禁止互相 import，而「谁也不知道
/// 有哪些 feature 依赖目录」，用一个自增信号解耦。
final class CatalogRevisionProvider
    extends $NotifierProvider<CatalogRevision, int> {
  /// 目录数据的版本号：同步成功后自增，用来让所有 catalog provider 重建。
  ///
  /// 放在 core 而不是各 feature：feature 之间禁止互相 import，而「谁也不知道
  /// 有哪些 feature 依赖目录」，用一个自增信号解耦。
  CatalogRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogRevisionHash();

  @$internal
  @override
  CatalogRevision create() => CatalogRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$catalogRevisionHash() => r'15bf70a2b66eb4e0cf46157c08afd03f95fba431';

/// 目录数据的版本号：同步成功后自增，用来让所有 catalog provider 重建。
///
/// 放在 core 而不是各 feature：feature 之间禁止互相 import，而「谁也不知道
/// 有哪些 feature 依赖目录」，用一个自增信号解耦。

abstract class _$CatalogRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CatalogSyncController)
final catalogSyncControllerProvider = CatalogSyncControllerProvider._();

final class CatalogSyncControllerProvider
    extends $NotifierProvider<CatalogSyncController, CatalogSyncState> {
  CatalogSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogSyncControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogSyncControllerHash();

  @$internal
  @override
  CatalogSyncController create() => CatalogSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogSyncState>(value),
    );
  }
}

String _$catalogSyncControllerHash() =>
    r'ee5cdc15f779d0195d1833a8c3e17e8ecb6ec3e9';

abstract class _$CatalogSyncController extends $Notifier<CatalogSyncState> {
  CatalogSyncState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CatalogSyncState, CatalogSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CatalogSyncState, CatalogSyncState>,
              CatalogSyncState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
