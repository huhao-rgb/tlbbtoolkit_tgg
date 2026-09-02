import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/tools/tool_catalog.dart';
import '../../shared/widgets/tool_hub_page.dart';
import '../../shared/widgets/tool_placeholder_page.dart';

part 'pet_routes.g.dart';

/// pet（宝宝）feature 的路由定义。
///
/// 分类根 `/pet` 是「宝宝工具」hub；三个工具为其二级页，
/// 与首页 / 侧栏目录一致。工具页暂用 `ToolPlaceholderPage` 骨架占位，
/// 逐个实现真实工具时替换对应 build。
@TypedGoRoute<PetHubRoute>(
  path: '/pet',
  name: '宝宝工具',
  routes: [
    TypedGoRoute<PetCalcRoute>(path: 'calc', name: '宝宝资质计算'),
    TypedGoRoute<PetProbRoute>(path: 'prob', name: '宝宝技能释放概率'),
    TypedGoRoute<PetSuitRoute>(path: 'suit', name: '宝宝套装图鉴'),
  ],
)
class PetHubRoute extends GoRouteData with $PetHubRoute {
  const PetHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolHubPage(group: ToolGroup.pet);
}

/// 宝宝资质计算（热门）。
class PetCalcRoute extends GoRouteData with $PetCalcRoute {
  const PetCalcRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolPlaceholderPage(tool: ToolCatalog.petCalc);
}

/// 技能释放概率。
class PetProbRoute extends GoRouteData with $PetProbRoute {
  const PetProbRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolPlaceholderPage(tool: ToolCatalog.petProb);
}

/// 宝宝套装图鉴。
class PetSuitRoute extends GoRouteData with $PetSuitRoute {
  const PetSuitRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolPlaceholderPage(tool: ToolCatalog.petSuit);
}
