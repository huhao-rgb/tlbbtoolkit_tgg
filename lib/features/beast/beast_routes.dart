import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/tools/tool_catalog.dart';
import '../../shared/widgets/tool_hub_page.dart';
import '../../shared/widgets/tool_placeholder_page.dart';

part 'beast_routes.g.dart';

/// beast（兽灵 · 兽魂）feature 的路由定义。
///
/// 分类根 `/beast` 是「兽灵 · 兽魂」hub；三个工具为其二级页。
@TypedGoRoute<BeastHubRoute>(
  path: '/beast',
  name: '兽灵 · 兽魂',
  routes: [
    TypedGoRoute<BeastSoulRoute>(path: 'soul', name: '兽魂查询'),
    TypedGoRoute<BeastIndexRoute>(path: 'index', name: '兽灵图鉴'),
    TypedGoRoute<BeastSkillRoute>(path: 'skill', name: '兽灵技能效果'),
  ],
)
class BeastHubRoute extends GoRouteData with $BeastHubRoute {
  const BeastHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolHubPage(group: ToolGroup.beast);
}

/// 兽魂查询。
class BeastSoulRoute extends GoRouteData with $BeastSoulRoute {
  const BeastSoulRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolPlaceholderPage(tool: ToolCatalog.beastSoul);
}

/// 兽灵图鉴。
class BeastIndexRoute extends GoRouteData with $BeastIndexRoute {
  const BeastIndexRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolPlaceholderPage(tool: ToolCatalog.beastIndex);
}

/// 兽灵技能效果。
class BeastSkillRoute extends GoRouteData with $BeastSkillRoute {
  const BeastSkillRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolPlaceholderPage(tool: ToolCatalog.beastSkill);
}
