// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeItem _$HomeItemFromJson(Map<String, dynamic> json) => _HomeItem(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  subtitle: json['subtitle'] as String? ?? '',
  isFavorite: json['isFavorite'] as bool? ?? false,
);

Map<String, dynamic> _$HomeItemToJson(_HomeItem instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'isFavorite': instance.isFavorite,
};
