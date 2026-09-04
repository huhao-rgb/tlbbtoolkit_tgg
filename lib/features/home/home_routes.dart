import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/home_page.dart';

part 'home_routes.g.dart';

/// home feature 的路由定义。
///
/// home 是 shell 底部 tab 的第一个分支，根路径 `/home`（首页）。
/// 各工具由 pet / beast / job / misc 四个 feature 提供，
/// 在 `app_router.dart` 中作为同分支内的 hub 子路由聚合（见各 feature 路由）。
@TypedGoRoute<HomeRoute>(path: '/home', name: '首页')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}
