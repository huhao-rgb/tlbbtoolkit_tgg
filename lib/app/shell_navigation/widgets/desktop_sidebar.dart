import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../gen/assets.gen.dart';
import '../../../shared/tools/tool_catalog.dart';
import '../../../shared/widgets/tg_icon.dart';
import '../../theme/design_tokens.dart';

/// 侧栏竖渐变（对应原型 `--sb-a → --sb-b`，深/浅两套）。
const _sbGradientDark = [Color(0xFF0C1016), Color(0xFF090C11)];
const _sbGradientLight = [Color(0xFFFBFAF7), Color(0xFFF2F0E8)];

/// hover 底色（`--hovnav`，约 .05）。
const _hoverDark = Color(0x0AFFFFFF);
const _hoverLight = Color(0x0D2A251D);

/// 桌面侧栏（对应原型 `<aside class="sidebar">`）。
///
/// 按原型 CSS 还原：
/// - 宽 236 · 竖渐变底 · `border-right` 1px（不再额外放分隔线）；
/// - 品牌区：天工阁 logo 徽标(38·r11·徽章投影) + serif 名称 + 副标；
/// - 分组标签：3px 金点（`--gold-dp`）+ 11px 字距2；
/// - 导航项：h38·r10 · 图标18 · 文字13.5；hover 提亮；激活项 金 .09/.10 底 +
///   `gold2` 文字 + 贴左缘 2.5px 金色渐变指示条；
/// - 底部：主题切换按钮(h36·r10·加强描边) + 版本/免责。
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({
    super.key,
    required this.currentLocation,
    this.hideBrand = false,
  });

  /// 当前 location（`/home`、`/pet/calc` …），用于高亮。
  final String currentLocation;

  /// 隐藏顶部品牌区（桌面自定义标题栏已展示品牌时，对应原型 desk 下
  /// `.brand{display:none}`）。
  final bool hideBrand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    return Container(
      width: TgSpacing.sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? _sbGradientDark : _sbGradientLight,
        ),
        border: Border(right: BorderSide(color: tg.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hideBrand)
            const SizedBox(height: 22)
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 8, 18),
              child: _Brand(),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              children: [
                const _GroupLabel('总览'),
                _SidebarItem(
                  svgIcon: 'home',
                  label: '首页',
                  active: currentLocation == '/home',
                  onTap: () => context.go('/home'),
                ),
                for (final group in ToolGroup.values) ...[
                  const SizedBox(height: 2),
                  _GroupLabel(group.label),
                  for (final tool in ToolCatalog.ofGroup(group))
                    _SidebarItem(
                      svgIcon: tool.icon,
                      label: tool.title,
                      active: currentLocation == tool.location,
                      onTap: () => context.go(tool.location),
                    ),
                ],
              ],
            ),
          ),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

/// 品牌区：天工阁 logo（深墨底金字徽标） + serif 名称 + 副标。
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        // brand-mark：38·r11 · 徽章投影（logo 自带深墨底与金描边，不再套金色渐变容器）
        Container(
          width: 38,
          height: 38,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TgRadius.lg),
            boxShadow: TgShadows.goldBadge,
          ),
          child: SvgPicture.asset(
            Assets.logo.logo,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // brand-name：serif 19 · 字距2
              Text('天工阁', style: TgType.score19.copyWith(color: tg.t1)),
              const SizedBox(height: 1),
              // brand-sub：10.5 · 字距1
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
    );
  }
}

/// 分组标题：金点 + 11px 字距2（padding 16/10/8）。
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 10, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(color: tg.goldDp, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TgType.tag.copyWith(color: tg.t3, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

/// 导航项：h38 · r10 · 图标18 · 文字13.5。
///
/// 激活态：金 .09/.10 底 · gold2 文字(500) · 贴左缘 2.5px 金色渐变指示条；
/// hover：提亮底色 + 文字转 t1（激活项保持激活样式）。
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.svgIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String svgIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;

    // 文字 / 图标颜色优先级：激活 > hover > 常态
    final Color textColor;
    final Color iconColor;
    if (widget.active) {
      textColor = tg.gold2;
      iconColor = tg.gold;
    } else if (_hover) {
      textColor = tg.t1;
      iconColor = tg.t2;
    } else {
      textColor = tg.t2;
      iconColor = tg.t3;
    }

    // 激活底色（金 .09 深 / .10 浅）与 hover 底色
    final Color? bg = widget.active
        ? tg.goldTint(isDark ? .09 : .10)
        : (_hover ? (isDark ? _hoverDark : _hoverLight) : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(TgRadius.md),
          // 关闭 InkWell 自带的整宽 hover/按压高亮，避免与内缩背景重叠成两层；
          // 悬停底色统一由下方的内缩背景块（MouseRegion 驱动）负责。
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            height: 38,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 背景块：左右各留 14px（对应 .sidebar 水平 padding），r10 圆角。
                if (bg != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(TgRadius.md),
                      ),
                    ),
                  ),
                // 激活指示条：贴侧栏最左缘（left:0）· 2.5 宽 · 渐变金 · 右圆角
                if (widget.active)
                  Positioned(
                    left: 0,
                    top: 9,
                    bottom: 9,
                    width: 2.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: tg.gradGold,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                // 内容距左 25（= 14 侧栏留白 + 11 nitem 内距），与原型图标位一致
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 11),
                  child: Row(
                    children: [
                      TgIcon(widget.svgIcon, size: 18, color: iconColor),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TgType.button.copyWith(
                            color: textColor,
                            fontWeight: widget.active
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部：主题切换按钮 + 版本 / 免责。
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
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // theme-btn：h36 · r10 · 加强描边 · 无底色 · 12.5px
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(TgRadius.md),
              onTap: () => ref
                  .read(appSettingsControllerProvider.notifier)
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
              child: Ink(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(TgRadius.md),
                  border: Border.all(color: tg.borderHi, width: 1),
                ),
                child: Row(
                  children: [
                    TgIcon(isDark ? 'sun' : 'moon', size: 18, color: tg.t2),
                    const SizedBox(width: 9),
                    Text(
                      isDark ? '浅色模式' : '深色模式',
                      style: TgType.label.copyWith(color: tg.t2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // side-foot 文案：版本（t2/500）+ 说明（t3 · 11 · 行高1.9）
          Text.rich(
            TextSpan(
              style: TgType.tag.copyWith(color: tg.t3, height: 1.9),
              children: [
                TextSpan(
                  text: 'v1.6.0',
                  style: TextStyle(color: tg.t2, fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: ' · 数据每日 06:00 同步\n'),
                const TextSpan(text: '玩家自制工具 · 与官方无关'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
