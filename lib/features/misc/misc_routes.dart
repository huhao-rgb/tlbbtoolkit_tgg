import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/tools/tool_catalog.dart';
import '../../shared/widgets/tool_hub_page.dart';
import 'domain/pet_market.dart';
import 'presentation/pages/misc_market_page.dart';
import 'presentation/pages/misc_regress_page.dart';

part 'misc_routes.g.dart';

/// misc（实用）feature 的路由定义。
///
/// 分类根 `/misc` 是「实用工具」hub；两个工具为其二级页。
@TypedGoRoute<MiscHubRoute>(
  path: '/misc',
  name: '实用工具',
  routes: [
    TypedGoRoute<MiscRegressRoute>(path: 'regress', name: '卡回归计算器'),
    TypedGoRoute<MiscMarketRoute>(
      path: 'market',
      name: '珍兽行情',
      routes: [
        // 商品详情作为嵌套子路由：push 压栈在行情列表之上，返回 pop 后列表
        // 滚动位置天然保留（不销毁），避免同页内切换详情导致的回顶跳动。
        TypedGoRoute<MiscPetDetailRoute>(path: 'detail', name: '商品详情'),
      ],
    ),
  ],
)
class MiscHubRoute extends GoRouteData with $MiscHubRoute {
  const MiscHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolHubPage(group: ToolGroup.misc);
}

/// 卡回归计算器。
class MiscRegressRoute extends GoRouteData with $MiscRegressRoute {
  const MiscRegressRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MiscRegressPage();
}

/// 珍兽行情分析（对应原型 `v-pet-market`）。
class MiscMarketRoute extends GoRouteData with $MiscMarketRoute {
  const MiscMarketRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MiscMarketPage();
}

/// 珍兽商品详情（对应原型 `v-pet-detail`）。商品对象经路由 extra 传入。
class MiscPetDetailRoute extends GoRouteData with $MiscPetDetailRoute {
  const MiscPetDetailRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final pet = state.extra is PetListing ? state.extra! as PetListing : null;
    return PetDetailPage(pet: pet);
  }
}
