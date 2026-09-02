import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import 'shell_navigation_state.dart';
import 'widgets/app_info_bar.dart';
import 'widgets/desktop_sidebar.dart';

/// shell 导航框架（响应式），按原型双端还原：
///
/// ```
/// mobile（<900）                  desktop（≥900）
/// ┌──────────────────┐        ┌────────┬──────────────────┐
/// │ 信息条(顶栏)      │        │ 品牌    │ 信息条            │
/// ├──────────────────┤        │ ─总览─  │ ──────────────── │
/// │                  │        │ 首页    │                  │
/// │      内容区       │        │ ─宝宝─  │     内容区        │
/// │                  │        │ …11工具 │                  │
/// ├──────────────────┤        │ 主题切换 │                  │
/// │ 首页│宝宝│兽灵│职业│        └────────┴──────────────────┘
/// └──────────────────┘
/// ```
///
/// - 信息条：显示当前路由名；二级页面显示返回按钮；右侧主题切换与设置入口；
/// - mobile：底部 4 段 tab（首页 / 宝宝 / 兽灵·兽魂 / 职业 → 各分类 hub）；
/// - desktop：左侧 236 宽原型侧栏（品牌 + 分组工具导航），无底部 tab。
class AppShellNavigation extends ConsumerWidget {
  const AppShellNavigation({
    super.key,
    required this.navigationShell,
  });

  /// go_router 注入的状态化导航壳，负责各 tab 分支的 Navigator 与切换。
  final StatefulNavigationShell navigationShell;

  /// 移动端底部 tab 项（分支 0..3 = home/pet/beast/job）。
  static const List<({IconData icon, IconData activeIcon, String label})>
      _destinations = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '首页'),
    (icon: Icons.pets, activeIcon: Icons.pets, label: '宝宝'),
    (
      icon: Icons.diamond_outlined,
      activeIcon: Icons.diamond,
      label: '兽灵·兽魂'
    ),
    (
      icon: Icons.sports_martial_arts_outlined,
      activeIcon: Icons.sports_martial_arts,
      label: '职业'
    ),
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

/// 移动端底部 tabbar（4 段：首页 / 宝宝 / 兽灵·兽魂 / 职业）。
class _MobileTabBar extends StatelessWidget {
  const _MobileTabBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      destinations: [
        for (final tab in AppShellNavigation._destinations)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.activeIcon),
            label: tab.label,
          ),
      ],
    );
  }
}
