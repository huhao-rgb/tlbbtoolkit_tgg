import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/pages/home_detail_page.dart';

part 'home_routes.g.dart';

/// home feature 的路由定义。
///
/// home 是 shell 底部 tab 的第一个分支，根路径 `/home`；
/// `detail/:id` 为二级页面，用于演示信息条上的返回按钮。
@TypedGoRoute<HomeRoute>(
  path: '/home',
  name: '工具箱',
  routes: [
    TypedGoRoute<HomeDetailRoute>(
      path: 'detail/:id',
      name: '工具详情',
    ),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// 首页条目的二级详情页路由。
class HomeDetailRoute extends GoRouteData with $HomeDetailRoute {
  const HomeDetailRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HomeDetailPage(id: id);
}
