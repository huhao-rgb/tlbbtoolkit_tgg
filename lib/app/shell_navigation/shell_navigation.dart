import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/app_window.dart';
import '../../core/responsive/breakpoints.dart';
import '../../shared/widgets/tg_icon.dart';
import '../../app/theme/design_tokens.dart';
import 'shell_navigation_state.dart';
import 'widgets/app_info_bar.dart';
import 'widgets/desktop_sidebar.dart';

/// 底部 tabbar 毛玻璃底色（对应原型 `--blur2`）：
/// 浅色 rgba(251,250,247,.94)；深色未在 :root 定义，沿用顶栏深色系但更实。
const _tabbarBlurDark = Color.fromRGBO(12, 16, 22, .94);
const _tabbarBlurLight = Color.fromRGBO(251, 250, 247, .94);

/// shell 导航框架（响应式），按原型双端还原：
///
/// ```
/// mobile（<900）                  desktop（≥900）
/// ┌──────────────────┐        ┌────────┬──────────────────┐
/// │ 信息条(顶栏)      │        │ 品牌    │ 信息条            │
/// ├──────────────────┤        │ ─总览─  │ ──────────────── │
/// │                  │        │ 首页    │                  │
/// │      内容区       │        │ ─实用─  │     内容区        │
/// │                  │        │ …15项   │                  │
/// ├──────────────────┤        │ 主题切换 │                  │
/// │ 首页│宝宝│兽灵│职业│实用     │        │                  │
/// └──────────────────┘        └────────┴──────────────────┘
/// ```
///
/// - 信息条：显示当前路由名；二级页面显示返回按钮；右侧主题切换与设置入口；
/// - mobile：底部 5 段 tab（首页 / 宝宝 / 兽灵 / 职业 / 实用 → 各分类 hub）；
/// - desktop：左侧 236 宽原型侧栏（品牌 + 分组工具导航），无底部 tab。
class AppShellNavigation extends ConsumerWidget {
  const AppShellNavigation({
    super.key,
    required this.navigationShell,
  });

  /// go_router 注入的状态化导航壳，负责各 tab 分支的 Navigator 与切换。
  final StatefulNavigationShell navigationShell;

  /// 移动端 tab 项（分支 0..4 = home/pet/beast/job/misc）。
  static const List<({String icon, String label})> _tabs = [
    (icon: 'home', label: '首页'),
    (icon: 'paw', label: '宝宝'),
    (icon: 'gem', label: '兽灵'),
    (icon: 'sword', label: '职业'),
    (icon: 'spark', label: '实用'),
  ];

  void _onTabSelected(int index) {
    // goBranch 保留各分支导航栈；点当前 tab 回到该分支根。
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _goBack() {
    // 返回当前分支的根页面（如 /pet/calc → 宝宝工具 hub）。
    navigationShell.goBranch(
      navigationShell.currentIndex,
      initialLocation: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(shellNavigationProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = Breakpoints.layoutOf(constraints.maxWidth);
        final desktop = layout == DeviceLayout.desktop;

        final infoBar = AppInfoBar(
          key: const Key('shell-info-bar'),
          title: navState.title,
          showBack: navState.isSecondLevel,
          onBack: _goBack,
          desktop: desktop,
        );

        switch (layout) {
          case DeviceLayout.mobile:
            return Scaffold(
              body: SafeArea(
                bottom: false,
                // 内容在下可滚动，毛玻璃顶栏悬浮覆盖其上。
                child: Stack(
                  children: [
                    Positioned.fill(child: navigationShell),
                    Positioned(top: 0, left: 0, right: 0, child: infoBar),
                  ],
                ),
              ),
              bottomNavigationBar: _MobileTabBar(
                currentIndex: navigationShell.currentIndex,
                onSelected: _onTabSelected,
              ),
            );
          case DeviceLayout.desktop:
            return Scaffold(
              body: Row(
                children: [
                  // 左侧 236 宽原型侧栏（自带竖渐变底 + 右边框）。
                  DesktopSidebar(
                    currentLocation: navState.location,
                    // 原生桌面（frameless + 自定义标题栏）隐藏品牌，见原型 desk。
                    hideBrand: isDesktopWindow,
                  ),
                  // 右侧：内容在下可滚动，毛玻璃顶栏悬浮覆盖。
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: navigationShell),
                        Positioned(top: 0, left: 0, right: 0, child: infoBar),
                      ],
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}

/// 移动端底部 tabbar（5 段：首页 / 宝宝 / 兽灵 / 职业 / 实用）。
///
/// 按原型 `.tabbar` 还原：
/// - 毛玻璃底（`blur 18px` + `--blur2`）+ 顶边 1px 边框；
/// - 每段：图标 21 + 文字 10.5（字距 1），gap 3，垂直居中；
/// - 选中项：图标 / 文字变 `gold2`，顶部一条 26×2.5px 金色渐变短线；
/// - 底部预留 safe-area。
class _MobileTabBar extends StatelessWidget {
  const _MobileTabBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      key: const Key('mobile-tab-bar'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tg.border, width: 1)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: isDark ? _tabbarBlurDark : _tabbarBlurLight,
            padding: EdgeInsets.only(bottom: bottom),
            child: SizedBox(
              height: TgSpacing.tabbarHeight,
              child: Row(
                children: [
                  for (var i = 0; i < AppShellNavigation._tabs.length; i++)
                    _TabItem(
                      tab: AppShellNavigation._tabs[i],
                      active: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个 tab（横向铺满 1/n）。
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final ({String icon, String label}) tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 选中指示条：顶部 26×2.5 金色渐变（下圆角）
                if (active)
                  Positioned(
                    top: 0,
                    width: 26,
                    height: 2.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: tg.gradGold,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TgIcon(
                      tab.icon,
                      size: 21,
                      color: active ? tg.gold2 : tg.t3,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      style: TgType.micro.copyWith(
                        color: active ? tg.gold2 : tg.t3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
