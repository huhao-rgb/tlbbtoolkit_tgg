// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'misc_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$miscHubRoute];

RouteBase get $miscHubRoute => GoRouteData.$route(
  path: '/misc',
  name: '实用工具',
  hasOverriddenOnExit: false,
  factory: $MiscHubRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'regress',
      name: '卡回归计算器',
      hasOverriddenOnExit: false,
      factory: $MiscRegressRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'market',
      name: '珍兽行情',
      hasOverriddenOnExit: false,
      factory: $MiscMarketRoute._fromState,
    ),
  ],
);

mixin $MiscHubRoute on GoRouteData {
  static MiscHubRoute _fromState(GoRouterState state) => const MiscHubRoute();

  @override
  String get location => GoRouteData.$location('/misc');

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

mixin $MiscRegressRoute on GoRouteData {
  static MiscRegressRoute _fromState(GoRouterState state) =>
      const MiscRegressRoute();

  @override
  String get location => GoRouteData.$location('/misc/regress');

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

mixin $MiscMarketRoute on GoRouteData {
  static MiscMarketRoute _fromState(GoRouterState state) =>
      const MiscMarketRoute();

  @override
  String get location => GoRouteData.$location('/misc/market');

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
