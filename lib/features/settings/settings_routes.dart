import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/features/settings/presentation/pages/settings_page.dart';

part 'settings_routes.g.dart';

/// settings feature 的路由定义。
///
/// 设置页是「实用」分支下的二级页（`/misc/settings`）：与其它工具二级页完全同构，
/// **不写 Scaffold / AppBar** —— 顶部信息条（含返回按钮）与底部 tabbar / 桌面侧栏
/// 均由 shell（`AppShellNavigation`）统一提供，页面自己只负责内容区
/// （见 `settings_page.dart` 的 `TgPageEntrance` + 悬浮栏预留内边距）。
///
/// 之所以与 `/misc` 平级（而非声明为 `/misc` 的子路由）：go_router 的嵌套子路由
/// 必须由其父路由所在文件（`misc_routes.dart`）声明，那会让 misc feature 反向依赖
/// settings feature；两者在 shell 中的渲染与返回行为一致（返回均回到「实用工具」hub）。
@TypedGoRoute<SettingsRoute>(path: '/misc/settings', name: '设置')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}
