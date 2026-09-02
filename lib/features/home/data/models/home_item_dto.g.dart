// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeItemDto _$HomeItemDtoFromJson(Map<String, dynamic> json) => _HomeItemDto(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  subtitle: json['subtitle'] as String?,
  isFavorite: json['isFavorite'] as bool? ?? false,
);

Map<String, dynamic> _$HomeItemDtoToJson(_HomeItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'isFavorite': instance.isFavorite,
    };
