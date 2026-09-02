import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/providers/settings_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// 应用根组件（组合根）。
///
/// 这里组装全局依赖（路由、主题、主题模式），
/// 各 feature 通过 ProviderScope 注入能力，彼此解耦。
class TlbbApp extends ConsumerWidget {
  const TlbbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TLBB Toolkit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
