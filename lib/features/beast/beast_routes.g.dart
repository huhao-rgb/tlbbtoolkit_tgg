// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beast_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$beastHubRoute];

RouteBase get $beastHubRoute => GoRouteData.$route(
  path: '/beast',
  name: '兽灵 · 兽魂',
  hasOverriddenOnExit: false,
  factory: $BeastHubRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'soul',
      name: '兽魂查询',
      hasOverriddenOnExit: false,
      factory: $BeastSoulRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'index',
      name: '兽灵图鉴',
      hasOverriddenOnExit: false,
      factory: $BeastIndexRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'skill',
      name: '兽灵技能效果',
      hasOverriddenOnExit: false,
      factory: $BeastSkillRoute._fromState,
    ),
  ],
);

mixin $BeastHubRoute on GoRouteData {
  static BeastHubRoute _fromState(GoRouterState state) => const BeastHubRoute();

  @override
  String get location => GoRouteData.$location('/beast');

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

mixin $BeastSoulRoute on GoRouteData {
  static BeastSoulRoute _fromState(GoRouterState state) =>
      const BeastSoulRoute();

  @override
  String get location => GoRouteData.$location('/beast/soul');

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

mixin $BeastIndexRoute on GoRouteData {
  static BeastIndexRoute _fromState(GoRouterState state) =>
      const BeastIndexRoute();

  @override
  String get location => GoRouteData.$location('/beast/index');

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

mixin $BeastSkillRoute on GoRouteData {
  static BeastSkillRoute _fromState(GoRouterState state) =>
      const BeastSkillRoute();

  @override
  String get location => GoRouteData.$location('/beast/skill');

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
