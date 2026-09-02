import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_item.freezed.dart';
part 'home_item.g.dart';

/// 首页条目领域实体。
///
/// 使用 freezed 生成不可变模型与 JSON 序列化。
@freezed
abstract class HomeItem with _$HomeItem {
  const factory HomeItem({
    required int id,
    required String title,
    @Default('') String subtitle,
    @Default(false) bool isFavorite,
  }) = _HomeItem;

  factory HomeItem.fromJson(Map<String, dynamic> json) =>
      _$HomeItemFromJson(json);
}
