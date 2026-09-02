import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/settings_page.dart';

part 'settings_routes.g.dart';

/// settings feature 的路由定义。
///
/// settings 是 shell 底部 tab 的第二个分支。
@TypedGoRoute<SettingsRoute>(path: '/settings', name: '设置')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}
