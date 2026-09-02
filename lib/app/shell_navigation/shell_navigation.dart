import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import 'shell_navigation_state.dart';

/// shell 导航框架（响应式）。
///
/// 按窗口宽度自适应两种布局：
///
/// ```
/// mobile（<900）                desktop（≥900）
/// ┌──────────────┐          ┌───────┬─────────────────┐
/// │ 信息条        │          │       │ 信息条           │
/// ├──────────────┤          │ 侧栏   ├─────────────────┤
/// │              │          │ 工具箱 │                 │
/// │   内容区      │          │ 设置   │   内容区         │
/// │              │          │       │                 │
/// ├──────────────┤          │       │                 │
/// │ [工具箱][设置] │          └───────┴─────────────────┘
/// └──────────────┘
/// ```
///
/// - 信息条：显示当前路由名称；二级页面显示返回按钮；
/// - mobile：中间内容区 + 底部 tabbar；
/// - desktop：左侧全高侧边栏，右侧顶部信息条 + 底部内容区。
class AppShellNavigation extends ConsumerWidget {
  const AppShellNavigation({
    super.key,
    required this.navigationShell,
  });

  /// go_router 注入的状态化导航壳，负责各 tab 分支的 Navigator 与切换。
  final StatefulNavigationShell navigationShell;

  /// tab 项配置（两种布局共用）。
  static const List<({IconData icon, IconData activeIcon, String label})>
      _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '工具箱'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: '设置'),
  ];

  void _onTabSelected(int index) {
    // goBranch 会保留各分支的导航栈状态。
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _goBack() {
    // 返回当前分支的根页面（一级页面）。
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

        // 公共信息条（两种布局共用）。
        final infoBar = _InfoBar(
          key: const Key('shell-info-bar'),
          title: navState.title,
          showBack: navState.isSecondLevel,
          onBack: _goBack,
        );

        switch (layout) {
          case DeviceLayout.mobile:
            return Scaffold(
              appBar: AppBar(title: infoBar),
              body: navigationShell,
              bottomNavigationBar: _MobileTabBar(
                currentIndex: navigationShell.currentIndex,
                onSelected: _onTabSelected,
              ),
            );
          case DeviceLayout.desktop:
            return Scaffold(
              body: Row(
                children: [
                  // 左侧全高侧边栏。
                  _DesktopSideBar(
                    currentIndex: navigationShell.currentIndex,
                    onSelected: _onTabSelected,
                  ),
                  const VerticalDivider(width: 1),
                  // 右侧：顶部信息条 + 底部内容区。
                  Expanded(
                    child: Column(
                      children: [
                        infoBar,
                        const Divider(height: 1),
                        Expanded(child: navigationShell),
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

/// 公共信息条。
///
/// 自绘容器（非 `AppBar`）：`AppBar` 内嵌 `Column` 会与测试的
/// `pumpAndSettle` 死锁，且语义上信息条更适合用普通容器实现。
class _InfoBar extends StatelessWidget {
  const _InfoBar({
    super.key,
    required this.title,
    required this.showBack,
    required this.onBack,
  });

  final String title;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '返回',
                onPressed: onBack,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

/// 移动端底部 tabbar。
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
        for (final tab in AppShellNavigation._tabs)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.activeIcon),
            label: tab.label,
          ),
      ],
    );
  }
}

/// 桌面端左侧导航栏。
class _DesktopSideBar extends StatelessWidget {
  const _DesktopSideBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: const SizedBox(height: 8),
      destinations: [
        for (final tab in AppShellNavigation._tabs)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.activeIcon),
            label: Text(tab.label),
          ),
      ],
    );
  }
}
