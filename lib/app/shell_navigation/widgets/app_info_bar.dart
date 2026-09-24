import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/features/music/presentation/widgets/music_player_button.dart';
import 'package:tlbbtoolkit/features/settings/presentation/providers/settings_providers.dart';
import 'package:tlbbtoolkit/features/settings/settings_routes.dart';
import 'package:tlbbtoolkit/app/theme/design_tokens.dart';

/// 顶栏毛玻璃参数与底部 tabbar 共用 [TgGlass]（对应原型 `--blur`）。

/// 公共信息条（对应原型 `.topbar`）。
///
/// 移动端为沉浸式顶栏：栏的背景（毛玻璃底）从屏幕顶部铺到状态栏背后，
/// 内容按顶部安全区内缩，保证按钮/标题不被状态栏（含刘海/挖孔）遮挡。
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
    // 移动端：状态栏/刘海/挖孔所在的安全区内缩，使栏内内容避开系统栏。
    final insets = MediaQuery.paddingOf(context);
    final titleStyle = TextStyle(
      fontSize: desktop ? 16.5 : 15,
      fontWeight: FontWeight.w600,
      letterSpacing: .5,
      color: tg.t1,
    );
    // 毛玻璃：悬浮于内容区之上，滚动到栏下的内容会经 blur 后透出。
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: TgGlass.sigma,
          sigmaY: TgGlass.sigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? TgGlass.dark : TgGlass.light,
            border: Border(bottom: BorderSide(color: tg.border, width: 1)),
          ),
          // 背景（DecoratedBox）铺满整个栏（含状态栏区域），
          // 内容在此基础上再叠加安全区内缩。
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              (desktop ? TgSpacing.pagePaddingDeskH : TgSpacing.pagePaddingMobileH) + insets.left,
              12 + insets.top,
              (desktop ? TgSpacing.pagePaddingDeskH : TgSpacing.pagePaddingMobileH) + insets.right,
              12,
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
                    // 怀旧音律：点击弹出播放列表与控制面板。
                    const MusicPlayerButton(),
                    const SizedBox(width: 10),
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
        style: TextStyle(fontSize: 11.5, letterSpacing: .5, color: tg.gold),
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

/// 顶栏设置入口：切到「实用」分支下的设置二级页（shell 内，保留信息条与底栏）。
class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TopButton(
      tooltip: '设置',
      icon: Icons.settings_outlined,
      onTap: () => context.go(SettingsRoute().location),
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
