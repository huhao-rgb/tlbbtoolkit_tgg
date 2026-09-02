import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/settings_page.dart';

part 'settings_routes.g.dart';

/// settings feature 的路由定义。
///
/// 使用 go_router_builder 的 `@TypedGoRoute` 生成类型安全路由，
/// 提供 `SettingsRoute().location` / `SettingsRoute().push(context)` 等能力。
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}
