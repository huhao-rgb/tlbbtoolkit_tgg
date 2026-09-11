import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/platform/app_window.dart';
import '../shared/widgets/window_title_bar.dart';
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
      title: '天工阁',
      debugShowCheckedModeBanner: false,
      // 中文本地化：让 Material 组件（日期/时间选择器等）显示中文
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: TgTheme.light,
      darkTheme: TgTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // 原生桌面：窗口顶部加 40px 自定义标题栏（frameless），内容整体下移；
      // Web / 移动端由宿主负责标题栏，原样返回。
      //
      // 同时在这里按当前主题设置系统栏（状态栏/导航栏）透明 + 图标明暗，
      // 配合 shell 顶栏毛玻璃 + Android edge-to-edge 实现沉浸式效果。
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final body = AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            // Android：状态栏/导航栏透明，露出顶栏毛玻璃与底部 tabbar 背景。
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            // 图标明暗跟随主题：深色 → 亮图标，浅色 → 暗图标。
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
        if (!isDesktopWindow) return body;
        return Column(
          children: [
            const TgWindowTitleBar(),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}
