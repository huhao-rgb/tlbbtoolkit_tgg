// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$jobHubRoute];

RouteBase get $jobHubRoute => GoRouteData.$route(
  path: '/job',
  name: '职业中心',
  hasOverriddenOnExit: false,
  factory: $JobHubRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'wudao',
      name: '职业武道',
      hasOverriddenOnExit: false,
      factory: $JobWudaoRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'skill',
      name: '职业技能库',
      hasOverriddenOnExit: false,
      factory: $JobSkillRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'point',
      name: '职业加点计算器',
      hasOverriddenOnExit: false,
      factory: $JobPointRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'artifact',
      name: '职业神器',
      hasOverriddenOnExit: false,
      factory: $JobArtifactRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'sect',
      name: '门派介绍',
      hasOverriddenOnExit: false,
      factory: $JobSectRoute._fromState,
    ),
  ],
);

mixin $JobHubRoute on GoRouteData {
  static JobHubRoute _fromState(GoRouterState state) => const JobHubRoute();

  @override
  String get location => GoRouteData.$location('/job');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JobWudaoRoute on GoRouteData {
  static JobWudaoRoute _fromState(GoRouterState state) =>
      JobWudaoRoute(sect: state.uri.queryParameters['sect']);

  JobWudaoRoute get _self => this as JobWudaoRoute;

  @override
  String get location => GoRouteData.$location(
    '/job/wudao',
    queryParams: {if (_self.sect != null) 'sect': _self.sect},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JobSkillRoute on GoRouteData {
  static JobSkillRoute _fromState(GoRouterState state) =>
      JobSkillRoute(sect: state.uri.queryParameters['sect']);

  JobSkillRoute get _self => this as JobSkillRoute;

  @override
  String get location => GoRouteData.$location(
    '/job/skill',
    queryParams: {if (_self.sect != null) 'sect': _self.sect},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JobPointRoute on GoRouteData {
  static JobPointRoute _fromState(GoRouterState state) =>
      JobPointRoute(sect: state.uri.queryParameters['sect']);

  JobPointRoute get _self => this as JobPointRoute;

  @override
  String get location => GoRouteData.$location(
    '/job/point',
    queryParams: {if (_self.sect != null) 'sect': _self.sect},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JobArtifactRoute on GoRouteData {
  static JobArtifactRoute _fromState(GoRouterState state) =>
      JobArtifactRoute(sect: state.uri.queryParameters['sect']);

  JobArtifactRoute get _self => this as JobArtifactRoute;

  @override
  String get location => GoRouteData.$location(
    '/job/artifact',
    queryParams: {if (_self.sect != null) 'sect': _self.sect},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JobSectRoute on GoRouteData {
  static JobSectRoute _fromState(GoRouterState state) => const JobSectRoute();

  @override
  String get location => GoRouteData.$location('/job/sect');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
