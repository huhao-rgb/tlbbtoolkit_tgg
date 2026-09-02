import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';

part 'settings_providers.g.dart';

/// 应用设置状态，读写均由 [SettingsRepository] 落盘。
///
/// `@riverpod` + `extends _$AppSettingsController` 由 riverpod_generator
/// 自动生成 `appSettingsControllerProvider`。
@riverpod
class AppSettingsController extends _$AppSettingsController {
  @override
  AppSettings build() {
    return ref.watch(settingsRepositoryProvider).getSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode.name));

  Future<void> toggleNotifications() =>
      _update((s) => s.copyWith(enableNotifications: !s.enableNotifications));

  Future<void> setNickname(String nickname) =>
      _update((s) => s.copyWith(nickname: nickname));

  Future<void> _update(AppSettings Function(AppSettings current) mutate) async {
    final next = mutate(state);
    state = next;
    await ref.read(settingsRepositoryProvider).saveSettings(next);
  }
}

/// 派生 provider：把设置中的主题字符串转换为 [ThemeMode]。
@riverpod
ThemeMode themeMode(Ref ref) {
  final mode = ref.watch(appSettingsControllerProvider).themeMode;
  return ThemeMode.values.firstWhere(
    (m) => m.name == mode,
    orElse: () => ThemeMode.system,
  );
}
