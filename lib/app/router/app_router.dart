import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_routes.dart' as home;
import '../../features/settings/settings_routes.dart' as settings;
import '../shell_navigation/shell_navigation.dart';

/// 全局路由表。
///
/// 根路由是 shell 导航框架（`StatefulShellRoute.indexedStack`）：
/// - 顶部公共信息条（当前路由名 + 二级页面返回按钮）
/// - 中间内容区
/// - 底部 tabbar 切换一级页面（home / settings 两个 tab 分支）
///
/// 各 feature 通过 `@TypedGoRoute` 生成 `$appRoutes`，在此聚合为 tab 分支。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: home.HomeRoute().location,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellNavigation(navigationShell: navigationShell),
        branches: [
          // tab 1：工具箱（home）
          StatefulShellBranch(routes: [...home.$appRoutes]),
          // tab 2：设置（settings）
          StatefulShellBranch(routes: [...settings.$appRoutes]),
        ],
      ),
    ],
  );
});
