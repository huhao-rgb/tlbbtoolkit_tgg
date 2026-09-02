import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:tlbbtoolkit/features/settings/domain/entities/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('设置仓储默认返回默认设置', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepositoryImpl(LocalStorage(prefs));

    expect(repo.getSettings(), const AppSettings());
  });

  test('设置仓储可以保存并读取设置', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepositoryImpl(LocalStorage(prefs));

    await repo.saveSettings(
      const AppSettings(themeMode: 'dark', enableNotifications: false),
    );

    final loaded = repo.getSettings();
    expect(loaded.themeMode, 'dark');
    expect(loaded.enableNotifications, false);
  });
}
