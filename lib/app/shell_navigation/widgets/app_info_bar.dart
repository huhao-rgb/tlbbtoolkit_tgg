import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../features/settings/settings_routes.dart';
import '../../theme/design_tokens.dart';

/// 顶栏半透明底色（对应原型 `--blur`，浅色 rgba(251,250,247,.82)；
/// 深色为原型占位缺值，按同构取 rgba(12,16,22,.82)）。
const _blurDark = Color.fromRGBO(12, 16, 22, .82);
const _blurLight = Color.fromRGBO(251, 250, 247, .82);

/// 公共信息条（对应原型 `.topbar`）。
///
/// 按原型 CSS 还原：
/// - 桌面 `padding 13/34`，移动 `12/16`；`gap 12`；底部分隔线由 shell 的 Divider 提供；
/// - 标题：桌面 16.5/600 · 字距.5，移动 15；
/// - 返回钮：30×30 · r9 · 加强描边（hover 金）；
/// - 右侧按钮组：34×34 · r10 · 加强描边（hover 金）；
/// - 版本 chip：金字 · 金 .32 描边 · 金 .08 底 · 胶囊（仅桌面）。
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

  /// 桌面布局（≥900）：右侧显示数据版本 chip，标题用 16.5px。
  final bool desktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    final titleStyle = TextStyle(
      fontSize: desktop ? 16.5 : 15,
      fontWeight: FontWeight.w600,
      letterSpacing: .5,
      color: tg.t1,
    );
    // 毛玻璃：悬浮于内容区之上，滚动到栏下的内容会经 blur 后透出。
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? _blurDark : _blurLight,
            border: Border(
              bottom: BorderSide(color: tg.border, width: 1),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: desktop ? 34 : 16,
              vertical: desktop ? 13 : 12,
            ),
            child: Row(
              children: [
                if (showBack) ...[
                  _TopButton(
                    key: const Key('shell-back-button'),
                    icon: Icons.arrow_back,
                    size: 30,
                    radius: 9,
                    iconSize: 16,
                    tooltip: '返回上一级',
                    onTap: onBack,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (desktop) ...[
                      const _VersionChip(),
                      const SizedBox(width: 10),
                    ],
                    _ThemeToggleButton(),
                    const SizedBox(width: 10),
                    _SettingsButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 数据版本 chip（仅桌面；金字 · 金描边 .32 · 金底 .08 · 胶囊）。
class _VersionChip extends StatelessWidget {
  const _VersionChip();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: tg.goldTint(.08),
        borderRadius: TgRadius.pillShape,
        border: Border.all(color: tg.goldTint(.32), width: 1),
      ),
      child: Text(
        '数据版本 v1.6.0',
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: .5,
          color: tg.gold,
        ),
      ),
    );
  }
}

/// 顶栏主题切换：快速在深浅之间切换（system 按当前亮度取反）。
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => brightness == Brightness.dark,
    };
    return _TopButton(
      tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      onTap: () => ref
          .read(appSettingsControllerProvider.notifier)
          .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

/// 顶栏设置入口：push 打开 shell 外的独立设置页。
class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TopButton(
      tooltip: '设置',
      icon: Icons.settings_outlined,
      onTap: () => context.push(SettingsRoute().location),
    );
  }
}

/// 顶栏描边小按钮（原型 .back-btn / .theme-top）：
/// 尺寸可配 · 加强描边 · 无底色；hover 时图标转 gold2、描边转金。
class _TopButton extends StatefulWidget {
  const _TopButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 34,
    this.radius = 10,
    this.iconSize = 17,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_TopButton> createState() => _TopButtonState();
}

class _TopButtonState extends State<_TopButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.radius),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Ink(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(
                  color: _hover ? tg.goldTint(.45) : tg.borderHi,
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: _hover ? tg.gold2 : tg.t2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
