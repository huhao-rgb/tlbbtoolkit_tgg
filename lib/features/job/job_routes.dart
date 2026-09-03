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
class JobWudaoRoute extends GoRouteData with $JobWudaoRoute {
  const JobWudaoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobWudaoPage();
}

/// 职业技能库。
class JobSkillRoute extends GoRouteData with $JobSkillRoute {
  const JobSkillRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobSkillPage();
}

/// 职业加点计算器（热门）。
class JobPointRoute extends GoRouteData with $JobPointRoute {
  const JobPointRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobPointPage();
}

/// 职业神器。
class JobArtifactRoute extends GoRouteData with $JobArtifactRoute {
  const JobArtifactRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobArtifactPage();
}

/// 门派介绍。
class JobSectRoute extends GoRouteData with $JobSectRoute {
  const JobSectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JobSectIntroPage();
}
