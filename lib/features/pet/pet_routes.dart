import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/tool_hub_page.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/beast_index_page.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/beast_skill_page.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/beast_soul_page.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_calc_page.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_prob_page.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_suit_page.dart';

part 'pet_routes.g.dart';

/// pet（珍兽）feature 的路由定义。
///
/// 分类根 `/pet` 是「珍兽工具」hub，其下二级页与首页 / 侧栏目录一致：
/// - 珍兽：资质计算 / 技能释放概率 / 套装图鉴（`PetCalcPage` 等真实页面）；
/// - 兽灵 · 兽魂：兽魂查询 / 兽灵图鉴 / 兽灵技能效果。原为独立一级页（`/beast`），
///   原型 v1.11.1 起并入珍兽，location 保持 `/pet/beast/*`。
@TypedGoRoute<PetHubRoute>(
  path: '/pet',
  name: '珍兽工具',
  routes: [
    TypedGoRoute<PetCalcRoute>(path: 'calc', name: '珍兽资质计算'),
    TypedGoRoute<PetProbRoute>(path: 'prob', name: '珍兽技能释放概率'),
    TypedGoRoute<PetSuitRoute>(path: 'suit', name: '珍兽套装图鉴'),
    TypedGoRoute<BeastSoulRoute>(path: 'beast/soul', name: '兽魂查询'),
    TypedGoRoute<BeastIndexRoute>(path: 'beast/index', name: '兽灵图鉴'),
    TypedGoRoute<BeastSkillRoute>(path: 'beast/skill', name: '兽灵技能效果'),
  ],
)
class PetHubRoute extends GoRouteData with $PetHubRoute {
  const PetHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolHubPage(group: ToolGroup.pet);
}

/// 珍兽资质计算（热门）。
class PetCalcRoute extends GoRouteData with $PetCalcRoute {
  const PetCalcRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PetCalcPage();
}

/// 技能释放概率。
class PetProbRoute extends GoRouteData with $PetProbRoute {
  const PetProbRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PetProbPage();
}

/// 珍兽套装图鉴。
class PetSuitRoute extends GoRouteData with $PetSuitRoute {
  const PetSuitRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PetSuitPage();
}

/// 兽魂查询（兽灵 · 兽魂并入珍兽后的二级页，location `/pet/beast/soul`）。
class BeastSoulRoute extends GoRouteData with $BeastSoulRoute {
  const BeastSoulRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BeastSoulPage();
}

/// 兽灵图鉴。
class BeastIndexRoute extends GoRouteData with $BeastIndexRoute {
  const BeastIndexRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BeastIndexPage();
}

/// 兽灵技能效果。
class BeastSkillRoute extends GoRouteData with $BeastSkillRoute {
  const BeastSkillRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BeastSkillPage();
}
