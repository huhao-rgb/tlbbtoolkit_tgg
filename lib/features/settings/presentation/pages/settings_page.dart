import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../providers/settings_providers.dart';

/// 设置页（一级 tab 页面）。
///
/// 页面自身不包含 Scaffold/AppBar：
/// 顶部信息条与底部 tabbar 由 shell 框架（`AppShellNavigation`）统一提供。
/// 桌面宽屏下内容限宽居中（`DesktopContentConstraint`）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(appSettingsControllerProvider.notifier);

    return DesktopContentConstraint(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('外观'),
                  subtitle: const Text('选择应用主题模式'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('跟随系统'),
                        icon: Icon(Icons.settings_brightness_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('浅色'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('深色'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) =>
                        notifier.setThemeMode(selection.first),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('通知提醒'),
                  subtitle: const Text('是否显示通知提醒'),
                  value: settings.enableNotifications,
                  onChanged: (_) => notifier.toggleNotifications(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于'),
              subtitle: Text('${AppConstants.appName} v1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}
