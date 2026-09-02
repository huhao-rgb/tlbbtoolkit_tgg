import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

part 'settings_repository_impl.g.dart';

/// 设置仓储的本地实现，基于 [LocalStorage] 持久化。
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._storage);

  static const String _storageKey = 'app_settings';

  final LocalStorage _storage;

  @override
  AppSettings getSettings() {
    final json = _storage.getJson(_storageKey);
    if (json == null) return const AppSettings();
    try {
      return AppSettings.fromJson(json);
    } on Object {
      // 数据损坏时回退到默认设置。
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _storage.setJson(_storageKey, settings.toJson());
  }
}

/// 设置仓储的依赖注入。
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepositoryImpl(ref.watch(localStorageProvider));
}
