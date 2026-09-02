import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../features/settings/settings_routes.dart';
import '../../../shared/tools/tool_catalog.dart';
import '../../../shared/widgets/tg_icon.dart';
import '../../theme/design_tokens.dart';

/// 桌面侧栏（对应原型 `<aside class="sidebar">`，宽 236）。
///
/// 信息架构：
/// ```
/// [品牌：天工阁 图标 + 名称 + 副标]
/// ─ 总览 ─ 首页
/// ─ 宝宝 ─ 资质计算 / 技能释放概率 / 套装图鉴
/// ─ 兽灵·兽魂 ─ 兽魂 / 图鉴 / 技能效果
/// ─ 职业 ─ 武道 / 技能库 / 加点 / 神器 / 门派
/// ─ 更多 ─ 设置
/// ────────
/// [主题切换 · 数据版本 · 免责]
/// ```
/// 工具项来自共享目录 `ToolCatalog`，按分组列出；当前项金色高亮。
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key, required this.currentLocation});

  /// 当前 location（`/home`、`/pet/calc` …），用于高亮。
  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tg = context.tg;
    return ColoredBox(
      color: tg.panel,
      child: SizedBox(
        width: TgSpacing.sidebarWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                children: [
                  const _GroupLabel('总览'),
                  _SidebarItem(
                    svgIcon: 'home',
                    label: '首页',
                    active: currentLocation == '/home',
                    onTap: () => context.go('/home'),
                  ),
                  for (final group in ToolGroup.values) ...[
                    const SizedBox(height: 10),
                    _GroupLabel(group.label),
                    for (final tool in ToolCatalog.ofGroup(group))
                      _SidebarItem(
                        svgIcon: tool.icon,
                        label: tool.title,
                        active: currentLocation == tool.location,
                        onTap: () => context.go(tool.location),
                      ),
                  ],
                  const SizedBox(height: 10),
                  const _GroupLabel('更多'),
                  _SidebarItem(
                    materialIcon: Icons.settings_outlined,
                    label: '设置',
                    active: false,
                    onTap: () => context.push(SettingsRoute().location),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

/// 品牌区：金渐变图标 + 名称 + 副标。
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: tg.gradGold,
              borderRadius: BorderRadius.circular(TgRadius.r12),
            ),
            child: const Text(
              '天',
              style: TextStyle(
                fontFamily: TgFonts.serif,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: TgTokens.btnInk,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '天工阁',
                  style: TgType.score19.copyWith(color: tg.t1),
                ),
                const SizedBox(height: 2),
                Text(
                  '天龙八部怀旧版 · 工具箱',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TgType.micro.copyWith(color: tg.t3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 分组标题（如 宝宝 / 兽灵·兽魂 / 职业）。
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Text(
        label,
        style: TgType.tag.copyWith(
          color: tg.t3,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 导航项：h38 · r10 · 图标 20 + 文字 13.5；选中金色左条 + 提亮底。
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    this.svgIcon,
    this.materialIcon,
    required this.label,
    required this.active,
    required this.onTap,
  }) : assert(svgIcon != null || materialIcon != null);

  /// SVG 资产名（工具 / 首页）。
  final String? svgIcon;

  /// Material 图标（如设置齿轮，svg_icons 未提供）。
  final IconData? materialIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final fg = active ? tg.gold2 : tg.t2;
    final Widget icon = svgIcon != null
        ? TgIcon(svgIcon!, size: 20, color: fg)
        : Icon(materialIcon, size: 20, color: fg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TgRadius.md),
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? tg.goldTint(.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(TgRadius.md),
          ),
          child: Row(
            children: [
              // 激活左侧金色指示条
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 3 : 0,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: tg.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TgType.button.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 侧栏底部：主题切换 + 数据版本 + 免责。
class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(TgRadius.md),
              onTap: () => ref
                  .read(appSettingsControllerProvider.notifier)
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
              child: Ink(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: tg.inset,
                  borderRadius: BorderRadius.circular(TgRadius.md),
                  border: Border.all(color: tg.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                      color: tg.t2,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isDark ? '浅色模式' : '深色模式',
                      style: TgType.button.copyWith(color: tg.t2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '数据版本 v1.6.0 · 每日 06:00 同步',
            textAlign: TextAlign.center,
            style: TgType.tag.copyWith(color: tg.t3),
          ),
          const SizedBox(height: 2),
          Text(
            '玩家自制工具 · 与官方无关',
            textAlign: TextAlign.center,
            style: TgType.tag.copyWith(color: tg.t3),
          ),
        ],
      ),
    );
  }
}
