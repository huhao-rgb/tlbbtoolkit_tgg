import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_routes.dart' as home;
import '../../features/settings/settings_routes.dart' as settings;

/// 全局路由表。
///
/// 聚合各 feature 通过 `@TypedGoRoute` 生成的路由（`$appRoutes`）。
/// 新增 feature 时，把它生成的 `$appRoutes` 追加到 [routes] 即可。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: home.HomeRoute().location,
    routes: [
      ...home.$appRoutes,
      ...settings.$appRoutes,
    ],
  );
});
