import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/beast/beast_routes.dart' as beast;
import '../../features/home/home_routes.dart' as home;
import '../../features/job/job_routes.dart' as job;
import '../../features/pet/pet_routes.dart' as pet;
import '../../features/settings/settings_routes.dart' as settings;
import '../shell_navigation/shell_navigation.dart';

/// 全局路由表。
///
/// 根路由是 shell 导航框架（`StatefulShellRoute.indexedStack`），移动端底部
/// tab 与桌面侧栏一一对应四个一级页面（首页 / 宝宝 / 兽灵·兽魂 / 职业）：
/// - `home`   → `/home`    首页（工具目录）
/// - `pet`    → `/pet`     宝宝工具 hub（+ 3 个二级工具）
/// - `beast`  → `/beast`   兽灵·兽魂 hub（+ 3 个二级工具）
/// - `job`    → `/job`     职业中心 hub（+ 5 个二级工具）
///
/// 各 feature 通过 `@TypedGoRoute` 生成 `$appRoutes`，在此按 tab 聚合为分支。
/// 「设置」为 shell 之外的独立全屏页（顶栏齿轮 / 桌面侧栏入口 push 打开）。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: home.HomeRoute().location,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellNavigation(navigationShell: navigationShell),
        branches: [
          // tab 1：首页（工具目录）
          StatefulShellBranch(routes: [...home.$appRoutes]),
          // tab 2：宝宝（pet）
          StatefulShellBranch(routes: [...pet.$appRoutes]),
          // tab 3：兽灵·兽魂（beast）
          StatefulShellBranch(routes: [...beast.$appRoutes]),
          // tab 4：职业（job）
          StatefulShellBranch(routes: [...job.$appRoutes]),
        ],
      ),
      // 设置：独立全屏页（不在 shell 内，自带返回）。
      ...settings.$appRoutes,
    ],
  );
});
