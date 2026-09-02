import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/settings_page.dart';

part 'settings_routes.g.dart';

/// settings feature 的路由定义。
///
/// 「设置」是 shell 之外的独立全屏页：由顶栏齿轮 / 桌面侧栏入口 push 打开，
/// 自带 Scaffold 与返回（不占用 shell 底部 tab / 侧栏分组）。
@TypedGoRoute<SettingsRoute>(path: '/settings', name: '设置')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(
          title: const Text('设置'),
          leading: IconButton(
            key: const Key('settings-back-button'),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
            onPressed: () => context.pop(),
          ),
        ),
        body: const SettingsPage(),
      );
}
