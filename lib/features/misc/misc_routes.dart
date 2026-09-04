import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/tools/tool_catalog.dart';
import '../../shared/widgets/tool_hub_page.dart';
import '../../shared/widgets/tool_placeholder_page.dart';

part 'misc_routes.g.dart';

/// misc（实用）feature 的路由定义。
///
/// 分类根 `/misc` 是「实用工具」hub；两个工具为其二级页。
/// 本轮工具先以占位页呈现（与项目早期 pet / job 一致），后续逐页落地。
@TypedGoRoute<MiscHubRoute>(
  path: '/misc',
  name: '实用工具',
  routes: [
    TypedGoRoute<MiscRegressRoute>(path: 'regress', name: '卡回归计算器'),
    TypedGoRoute<MiscMarketRoute>(path: 'market', name: '珍兽行情'),
  ],
)
class MiscHubRoute extends GoRouteData with $MiscHubRoute {
  const MiscHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolHubPage(group: ToolGroup.misc);
}

/// 卡回归计算器（占位）。
class MiscRegressRoute extends GoRouteData with $MiscRegressRoute {
  const MiscRegressRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ToolPlaceholderPage(tool: ToolCatalog.miscRegress);
}

/// 珍兽行情（占位）。
class MiscMarketRoute extends GoRouteData with $MiscMarketRoute {
  const MiscMarketRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ToolPlaceholderPage(tool: ToolCatalog.miscMarket);
}
