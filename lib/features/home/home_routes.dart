import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/home_page.dart';

part 'home_routes.g.dart';

/// home feature 的路由定义。
///
/// 使用 go_router_builder 的 `@TypedGoRoute` 生成类型安全路由，
/// 提供 `HomeRoute().location` / `HomeRoute().go(context)` 等能力。
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HomePage();
}
