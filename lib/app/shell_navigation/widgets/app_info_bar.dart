import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../features/settings/settings_routes.dart';
import '../../theme/design_tokens.dart';

/// 公共信息条（对应原型 `.topbar`）。
///
/// 布局：`[返回按钮?] 标题 …… [数据版本 chip（桌面）][主题切换][设置]`
/// 信息条用普通容器实现（避免 `AppBar` 内嵌导致的测试 `pumpAndSettle` 死锁）。
class AppInfoBar extends ConsumerWidget {
  const AppInfoBar({
    super.key,
    required this.title,
    required this.showBack,
    required this.onBack,
    this.desktop = false,
  });

  final String title;
  final bool showBack;
  final VoidCallback onBack;

  /// 桌面布局（≥900）：右侧显示数据版本 chip，标题用 17px。
  final bool desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tg = context.tg;
    final titleStyle = desktop
        ? TgType.topTitle.copyWith(color: tg.t1)
        : TgType.topTitle.copyWith(color: tg.t1, fontSize: 15);
    return Material(
      color: tg.panel,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                key: const Key('shell-back-button'),
                icon: const Icon(Icons.arrow_back),
                tooltip: '返回上一级',
                onPressed: onBack,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (desktop) ...[
              const _VersionChip(),
              const SizedBox(width: 8),
            ],
            _ThemeToggleButton(),
            _SettingsButton(),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// 数据版本 chip（仅桌面展示；数据源 tg JSON v1.6.0）。
class _VersionChip extends StatelessWidget {
  const _VersionChip();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: TgRadius.pillShape,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Text(
        '数据版本 v1.6.0',
        style: TgType.tag.copyWith(color: tg.t3, letterSpacing: .5),
      ),
    );
  }
}

/// 顶栏主题切换：快速在深浅之间切换（system 按当前亮度取反）。
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tg = context.tg;
    final mode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => brightness == Brightness.dark,
    };
    return IconButton(
      tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 20,
        color: tg.t2,
      ),
      onPressed: () => ref
          .read(appSettingsControllerProvider.notifier)
          .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

/// 顶栏设置入口：push 打开 shell 外的独立设置页。
class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return IconButton(
      tooltip: '设置',
      icon: Icon(Icons.settings_outlined, size: 20, color: tg.t2),
      onPressed: () => context.push(SettingsRoute().location),
    );
  }
}
