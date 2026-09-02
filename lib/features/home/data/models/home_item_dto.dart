import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/home_item.dart';

part 'home_item_dto.freezed.dart';
part 'home_item_dto.g.dart';

/// 首页条目的数据传输对象（DTO）。
///
/// DTO 用于对接外部数据（接口/文件），通过 [toEntity] 转换为领域实体，
/// 避免外部数据结构侵入领域层。
@freezed
abstract class HomeItemDto with _$HomeItemDto {
  // 私有空构造函数：让 freezed 生成代码 extend 本类，
  // 从而继承下面定义的自定义方法 toEntity()。
  const HomeItemDto._();

  const factory HomeItemDto({
    required int id,
    required String title,
    String? subtitle,
    @Default(false) bool isFavorite,
  }) = _HomeItemDto;

  factory HomeItemDto.fromJson(Map<String, dynamic> json) =>
      _$HomeItemDtoFromJson(json);

  /// DTO → 领域实体。
  HomeItem toEntity() => HomeItem(
        id: id,
        title: title,
        subtitle: subtitle ?? '',
        isFavorite: isFavorite,
      );
}
