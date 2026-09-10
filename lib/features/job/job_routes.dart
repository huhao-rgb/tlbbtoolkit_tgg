import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/tools/tool_catalog.dart';
import '../../shared/widgets/tool_hub_page.dart';
import 'presentation/pages/job_artifact_page.dart';
import 'presentation/pages/job_point_page.dart';
import 'presentation/pages/job_sect_intro_page.dart';
import 'presentation/pages/job_skill_page.dart';
import 'presentation/pages/job_wudao_page.dart';

part 'job_routes.g.dart';

/// job（职业）feature 的路由定义。
///
/// 分类根 `/job` 是「职业中心」hub；五个工具为其二级页。
@TypedGoRoute<JobHubRoute>(
  path: '/job',
  name: '职业中心',
  routes: [
    TypedGoRoute<JobWudaoRoute>(path: 'wudao', name: '职业武道'),
    TypedGoRoute<JobSkillRoute>(path: 'skill', name: '职业技能库'),
    TypedGoRoute<JobPointRoute>(path: 'point', name: '职业加点计算器'),
    TypedGoRoute<JobArtifactRoute>(path: 'artifact', name: '职业神器'),
    TypedGoRoute<JobSectRoute>(path: 'sect', name: '门派介绍'),
  ],
)
class JobHubRoute extends GoRouteData with $JobHubRoute {
  const JobHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ToolHubPage(group: ToolGroup.job);
}

/// 职业武道。
///
/// 可选 query 参数 `sect`：初始门派 key（门派介绍页「深入这个门派」跳转时携带）。
class JobWudaoRoute extends GoRouteData with $JobWudaoRoute {
  const JobWudaoRoute({this.sect});

  /// 初始门派 key（如 `shaolin`；query 参数 `sect`）。
  final String? sect;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JobWudaoPage(initialSect: sect);
}

/// 职业技能库。
///
/// 可选 query 参数 `sect`：初始门派 key（门派介绍页「深入这个门派」跳转时携带）。
class JobSkillRoute extends GoRouteData with $JobSkillRoute {
  const JobSkillRoute({this.sect});

  /// 初始门派 key（如 `shaolin`；query 参数 `sect`）。
  final String? sect;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JobSkillPage(initialSect: sect);
}

/// 职业加点计算器（热门）。
///
/// 可选 query 参数 `sect`：初始门派 key（门派介绍页「深入这个门派」跳转时携带）。
class JobPointRoute extends GoRouteData with $JobPointRoute {
  const JobPointRoute({this.sect});

  /// 初始门派 key（如 `shaolin`；query 参数 `sect`）。
  final String? sect;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JobPointPage(initialSect: sect);
}

/// 职业神器。
///
/// 可选 query 参数 `sect`：初始门派 key（门派介绍页「深入这个门派」跳转时携带）。
class JobArtifactRoute extends GoRouteData with $JobArtifactRoute {
  const JobArtifactRoute({this.sect});

  /// 初始门派 key（如 `shaolin`；query 参数 `sect`）。
  final String? sect;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JobArtifactPage(initialSect: sect);
}

/// 门派介绍。
class JobSectRoute extends GoRouteData with $JobSectRoute {
  const JobSectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobSectIntroPage();
}
