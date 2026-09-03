import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../router/app_router.dart';

part 'shell_navigation_state.g.dart';

/// 信息条所需的当前导航状态。
class ShellNavigationState {
  const ShellNavigationState({
    required this.title,
    required this.isSecondLevel,
    required this.location,
  });

  /// 当前路由名称（信息条标题）。
  final String title;

  /// 是否为二级页面（决定是否显示返回按钮）。
  final bool isSecondLevel;

  /// 当前完整 location（如 `/home`、`/pet/calc`），供侧栏高亮判断。
  final String location;
}

/// 监听 GoRouter 状态变化，推导信息条所需的标题与是否二级页面。
///
/// go_router 的路由匹配树中，shell 路由是**嵌套**结构
/// （`ShellRouteMatch` 内含分支路由链）：
/// - 一级页面：shell → 分支根，共 2 个匹配；
/// - 二级页面：shell → 分支根 → 二级路由，共 3 个及以上匹配。
@riverpod
class ShellNavigation extends _$ShellNavigation {
  /// 是否已排队一次“延迟同步”（router 在构建期连续通知时避免重复调度）。
  bool _updateScheduled = false;

  @override
  ShellNavigationState build() {
    final router = ref.watch(routerProvider);
    void onChanged() {
      // go_router 在启动首帧 / 首次重定向时可能于 widget 树构建期间通知，
      // 此时不能同步修改 provider（Riverpod 会抛错）。改为本次构建结束后
      // 再取 router 最新配置更新，保证各监听方拿到一致状态。
      if (_updateScheduled) return;
      _updateScheduled = true;
      Future(() {
        _updateScheduled = false;
        if (!ref.mounted) return;
        state = _derive(router);
      });
    }

    router.routerDelegate.addListener(onChanged);
    ref.onDispose(() => router.routerDelegate.removeListener(onChanged));

    return _derive(router);
  }

  ShellNavigationState _derive(GoRouter router) {
    final configuration = router.routerDelegate.currentConfiguration;
    final leaf = configuration.lastOrNull;
    if (leaf == null) {
      return const ShellNavigationState(
        title: '',
        isSecondLevel: false,
        location: '',
      );
    }

    // 递归统计匹配数（含 shell 嵌套），> 2 说明当前是二级页面。
    final matchCount = _countMatches(configuration.matches);
    final isSecondLevel = matchCount > 2;

    return ShellNavigationState(
      title: leaf.route.name ?? '',
      isSecondLevel: isSecondLevel,
      location: configuration.uri.toString(),
    );
  }

  /// 递归统计路由匹配数量（[ShellRouteMatch] 内含嵌套匹配）。
  int _countMatches(List<RouteMatchBase> matches) {
    var count = 0;
    for (final match in matches) {
      count++;
      if (match is ShellRouteMatch) {
        count += _countMatches(match.matches);
      }
    }
    return count;
  }
}
