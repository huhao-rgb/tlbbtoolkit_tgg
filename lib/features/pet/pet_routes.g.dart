// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$petHubRoute];

RouteBase get $petHubRoute => GoRouteData.$route(
  path: '/pet',
  name: '宝宝工具',
  hasOverriddenOnExit: false,
  factory: $PetHubRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'calc',
      name: '宝宝资质计算',
      hasOverriddenOnExit: false,
      factory: $PetCalcRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'prob',
      name: '宝宝技能释放概率',
      hasOverriddenOnExit: false,
      factory: $PetProbRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'suit',
      name: '宝宝套装图鉴',
      hasOverriddenOnExit: false,
      factory: $PetSuitRoute._fromState,
    ),
  ],
);

mixin $PetHubRoute on GoRouteData {
  static PetHubRoute _fromState(GoRouterState state) => const PetHubRoute();

  @override
  String get location => GoRouteData.$location('/pet');

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

mixin $PetCalcRoute on GoRouteData {
  static PetCalcRoute _fromState(GoRouterState state) => const PetCalcRoute();

  @override
  String get location => GoRouteData.$location('/pet/calc');

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

mixin $PetProbRoute on GoRouteData {
  static PetProbRoute _fromState(GoRouterState state) => const PetProbRoute();

  @override
  String get location => GoRouteData.$location('/pet/prob');

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

mixin $PetSuitRoute on GoRouteData {
  static PetSuitRoute _fromState(GoRouterState state) => const PetSuitRoute();

  @override
  String get location => GoRouteData.$location('/pet/suit');

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
