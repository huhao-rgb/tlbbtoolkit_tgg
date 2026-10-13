// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reg_sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 卡回归云同步控制器。
///
/// 触发时机：
/// - **启动**：读配对凭据 → 拉取一次（[build] 内异步启动）；
/// - **本地变更**：页面每次落盘后调用 [markDirty]，防抖 [_debounceDelay] 后推送；
/// - **手动**：[syncNow]。
///
/// 三条产品红线：本地永远可用；失败不抛给 UI（只改徽标状态）；未配对时零网络请求。

@ProviderFor(RegSyncController)
final regSyncControllerProvider = RegSyncControllerProvider._();

/// 卡回归云同步控制器。
///
/// 触发时机：
/// - **启动**：读配对凭据 → 拉取一次（[build] 内异步启动）；
/// - **本地变更**：页面每次落盘后调用 [markDirty]，防抖 [_debounceDelay] 后推送；
/// - **手动**：[syncNow]。
///
/// 三条产品红线：本地永远可用；失败不抛给 UI（只改徽标状态）；未配对时零网络请求。
final class RegSyncControllerProvider
    extends $NotifierProvider<RegSyncController, RegSyncState> {
  /// 卡回归云同步控制器。
  ///
  /// 触发时机：
  /// - **启动**：读配对凭据 → 拉取一次（[build] 内异步启动）；
  /// - **本地变更**：页面每次落盘后调用 [markDirty]，防抖 [_debounceDelay] 后推送；
  /// - **手动**：[syncNow]。
  ///
  /// 三条产品红线：本地永远可用；失败不抛给 UI（只改徽标状态）；未配对时零网络请求。
  RegSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regSyncControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regSyncControllerHash();

  @$internal
  @override
  RegSyncController create() => RegSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegSyncState>(value),
    );
  }
}

String _$regSyncControllerHash() => r'226db84705ec16a91dce50c50e0593bee6a7a5c7';

/// 卡回归云同步控制器。
///
/// 触发时机：
/// - **启动**：读配对凭据 → 拉取一次（[build] 内异步启动）；
/// - **本地变更**：页面每次落盘后调用 [markDirty]，防抖 [_debounceDelay] 后推送；
/// - **手动**：[syncNow]。
///
/// 三条产品红线：本地永远可用；失败不抛给 UI（只改徽标状态）；未配对时零网络请求。

abstract class _$RegSyncController extends $Notifier<RegSyncState> {
  RegSyncState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RegSyncState, RegSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegSyncState, RegSyncState>,
              RegSyncState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
