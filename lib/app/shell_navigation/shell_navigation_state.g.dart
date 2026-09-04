// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_navigation_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 监听 GoRouter 状态变化，推导信息条所需的标题与是否二级页面。
///
/// go_router 的路由匹配树中，shell 路由是**嵌套**结构
/// （`ShellRouteMatch` 内含分支路由链）：
/// - 一级页面：shell → 分支根，共 2 个匹配；
/// - 二级页面：shell → 分支根 → 二级路由，共 3 个及以上匹配。

@ProviderFor(ShellNavigation)
final shellNavigationProvider = ShellNavigationProvider._();

/// 监听 GoRouter 状态变化，推导信息条所需的标题与是否二级页面。
///
/// go_router 的路由匹配树中，shell 路由是**嵌套**结构
/// （`ShellRouteMatch` 内含分支路由链）：
/// - 一级页面：shell → 分支根，共 2 个匹配；
/// - 二级页面：shell → 分支根 → 二级路由，共 3 个及以上匹配。
final class ShellNavigationProvider
    extends $NotifierProvider<ShellNavigation, ShellNavigationState> {
  /// 监听 GoRouter 状态变化，推导信息条所需的标题与是否二级页面。
  ///
  /// go_router 的路由匹配树中，shell 路由是**嵌套**结构
  /// （`ShellRouteMatch` 内含分支路由链）：
  /// - 一级页面：shell → 分支根，共 2 个匹配；
  /// - 二级页面：shell → 分支根 → 二级路由，共 3 个及以上匹配。
  ShellNavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellNavigationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellNavigationHash();

  @$internal
  @override
  ShellNavigation create() => ShellNavigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShellNavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShellNavigationState>(value),
    );
  }
}

String _$shellNavigationHash() => r'd24520ed803fdfbf4549f5916671d00c510dbc61';

/// 监听 GoRouter 状态变化，推导信息条所需的标题与是否二级页面。
///
/// go_router 的路由匹配树中，shell 路由是**嵌套**结构
/// （`ShellRouteMatch` 内含分支路由链）：
/// - 一级页面：shell → 分支根，共 2 个匹配；
/// - 二级页面：shell → 分支根 → 二级路由，共 3 个及以上匹配。

abstract class _$ShellNavigation extends $Notifier<ShellNavigationState> {
  ShellNavigationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShellNavigationState, ShellNavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShellNavigationState, ShellNavigationState>,
              ShellNavigationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
