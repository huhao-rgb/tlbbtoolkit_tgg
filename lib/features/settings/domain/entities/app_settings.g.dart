// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  themeMode: json['themeMode'] as String? ?? 'system',
  enableNotifications: json['enableNotifications'] as bool? ?? true,
  nickname: json['nickname'] as String? ?? '',
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'enableNotifications': instance.enableNotifications,
      'nickname': instance.nickname,
    };
