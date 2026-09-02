import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// 应用设置领域实体，持久化为 JSON。
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// 主题模式：'system' | 'light' | 'dark'。
    ///
    /// 使用字符串便于 JSON 序列化，展示层再转换为 [ThemeMode]。
    @Default('system') String themeMode,

    @Default(true) bool enableNotifications,

    @Default('') String nickname,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
