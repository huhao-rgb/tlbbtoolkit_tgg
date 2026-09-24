import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/constants/app_constants.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/page_head.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_note_bar.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_segmented.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_switch.dart';
import 'package:tlbbtoolkit/features/settings/presentation/providers/settings_providers.dart';

/// 主题模式分段选项（(值, 文案)）。
const _themeOptions = <(ThemeMode, String)>[
  (ThemeMode.system, '跟随系统'),
  (ThemeMode.light, '浅色'),
  (ThemeMode.dark, '深色'),
];

/// 设置页（「实用」分支下的二级页 `/misc/settings`）。
///
/// 与其它工具二级页同一套页面框架：页面自身**不含** Scaffold/AppBar，
/// 顶部信息条（含返回）与底部 tabbar / 桌面侧栏由 shell（`AppShellNavigation`）提供；
/// 内容区用 `TgPageEntrance` + 悬浮栏预留内边距，卡片 / 分段控件 / 开关 /
/// 页头全部复用设计规范组件（`TgSegmented`、`TgSwitchRow`、`TgPageHead`…）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(appSettingsControllerProvider.notifier);
    // 版本号运行时读取（来源 pubspec.yaml）；未就绪 / 读取失败时不展示版本段。
    final version = ref.watch(packageInfoProvider).value?.version;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return TgPageEntrance(
          child: SingleChildScrollView(
            padding: compact
                ? const EdgeInsets.fromLTRB(
                    TgSpacing.pagePaddingMobileH,
                    20 + Breakpoints.topbarOverlayHeight,
                    TgSpacing.pagePaddingMobileH,
                    40 + Breakpoints.tabbarOverlayHeight, // 预留悬浮底栏
                  )
                : TgSpacing.pagePadding.copyWith(
                    top:
                        TgSpacing.pagePadding.top +
                        Breakpoints.topbarOverlayHeight, // 预留悬浮顶栏
                  ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TgPageHead(
                      crumbLeft: ToolGroup.misc.short,
                      crumbTail: ' / 设置',
                      onCrumbLeftTap: () =>
                          context.go(ToolGroup.misc.hubLocation),
                      title: '设置',
                      subtitle: '外观、通知与应用信息',
                    ),
                    // 外观卡：主题模式（分段切换）+ 通知提醒（开关行）
                    _SectionCard(
                      children: [
                        _SectionRow(
                          icon: 'sun',
                          title: '外观',
                          subtitle: '选择应用主题模式',
                          trailing: TgSegmented(
                            key: const Key('settings-theme-mode'),
                            values: [for (final o in _themeOptions) o.$2],
                            selected: _labelOf(themeMode),
                            onSelect: (label) =>
                                notifier.setThemeMode(_modeOf(label)),
                          ),
                        ),
                        TgCardPadding(
                          base: const EdgeInsets.symmetric(
                            horizontal: TgSpacing.lg,
                            vertical: TgSpacing.s13,
                          ),
                          child: TgSwitchRow(
                            label: '通知提醒',
                            subtitle: '是否显示通知提醒',
                            value: settings.enableNotifications,
                            onChanged: (_) => notifier.toggleNotifications(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TgSpacing.md),
                    // 关于卡
                    _SectionCard(
                      children: [
                        _SectionRow(
                          icon: 'info',
                          title: '关于',
                          subtitle: [
                            if (version != null)
                              '${AppConstants.appName} v$version'
                            else
                              AppConstants.appName,
                            '玩家自制工具，与官方无关',
                          ].join(' · '),
                        ),
                      ],
                    ),
                    const SizedBox(height: TgSpacing.s18),
                    // 页脚注（`.note`：inset 底 + info 图标）
                    const TgNoteBar(
                      accent: TgNoteAccent.plain,
                      text: '设置保存在本机，不会上传任何数据。',
                    ),
                    const SizedBox(height: TgSpacing.s34),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [ThemeMode] → 分段文案。
String _labelOf(ThemeMode mode) =>
    _themeOptions.firstWhere((o) => o.$1 == mode).$2;

/// 分段文案 → [ThemeMode]。
ThemeMode _modeOf(String label) =>
    _themeOptions.firstWhere((o) => o.$2 == label).$1;

/// 分组卡（`.card`）：卡片底 + 1px 描边 + r16，行间自动补 1px 分隔线。
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  /// 卡片内的行；相邻行之间自动插入分隔线。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: tg.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 卡片内的一行：图标砖 + 标题 / 说明（[trailing] 渲染在其下方，如分段按钮组）。
class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  /// SVG 图标资产名（见 `TgIcon`）。
  final String icon;
  final String title;
  final String subtitle;

  /// 行下方控件（如分段按钮组）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgCardPadding(
      base: EdgeInsets.fromLTRB(
        TgSpacing.lg,
        TgSpacing.md,
        TgSpacing.lg,
        trailing == null ? TgSpacing.md : TgSpacing.s18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标砖：34×34 · r10 · 金 10% 底 + 28% 描边（同工具卡 tile 口径）
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tg.gold.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(TgRadius.md),
                  border: Border.all(
                    color: tg.gold.withValues(alpha: .28),
                    width: 1,
                  ),
                ),
                child: TgIcon(icon, size: 17, color: tg.gold),
              ),
              const SizedBox(width: TgSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TgType.cardTitle.copyWith(color: tg.t1)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TgType.caption.copyWith(color: tg.t3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: TgSpacing.s14),
            trailing!,
          ],
        ],
      ),
    );
  }
}
