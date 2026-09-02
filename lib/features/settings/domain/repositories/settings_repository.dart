import '../entities/app_settings.dart';

/// 设置仓储抽象。
abstract interface class SettingsRepository {
  AppSettings getSettings();

  Future<void> saveSettings(AppSettings settings);
}
