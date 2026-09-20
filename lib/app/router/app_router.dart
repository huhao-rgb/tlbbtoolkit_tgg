import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/features/beast/beast_routes.dart' as beast;
import 'package:tlbbtoolkit/features/home/home_routes.dart' as home;
import 'package:tlbbtoolkit/features/job/job_routes.dart' as job;
import 'package:tlbbtoolkit/features/misc/misc_routes.dart' as misc;
import 'package:tlbbtoolkit/features/pet/pet_routes.dart' as pet;
import 'package:tlbbtoolkit/features/settings/settings_routes.dart' as settings;
import 'package:tlbbtoolkit/app/shell_navigation/shell_navigation.dart';

/// 全局路由表。
///
/// 根路由是 shell 导航框架（`StatefulShellRoute.indexedStack`），移动端底部
/// tab 与桌面侧栏一一对应五个一级页面（首页 / 宝宝 / 兽灵·兽魂 / 职业 / 实用）：
/// - `home`   → `/home`    首页（工具目录）
/// - `pet`    → `/pet`     宝宝工具 hub（+ 3 个二级工具）
/// - `beast`  → `/beast`   兽灵·兽魂 hub（+ 3 个二级工具）
/// - `job`    → `/job`     职业中心 hub（+ 5 个二级工具）
/// - `misc`   → `/misc`    实用工具 hub（+ 2 个二级工具）
///
/// 各 feature 通过 `@TypedGoRoute` 生成 `$appRoutes`，在此按 tab 聚合为分支。
/// 「设置」(`/misc/settings`) 挂在「实用」分支内，作为 shell 内的二级页，
/// 与其它工具页共享同一套页面框架（信息条 + 返回 + 底部 tabbar / 侧栏）。
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
          // tab 5：实用（misc）—— 同时容纳「设置」二级页（/misc/settings），
          // 使其与其它二级页一样由 shell 提供信息条 / 返回 / 底部 tabbar。
          StatefulShellBranch(
            routes: [...misc.$appRoutes, ...settings.$appRoutes],
          ),
        ],
      ),
    ],
  );
});
