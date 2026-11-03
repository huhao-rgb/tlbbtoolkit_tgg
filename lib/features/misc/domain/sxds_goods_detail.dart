import 'package:flutter/foundation.dart';

/// 神仙代售单个商品（账号 / 珍兽 …）的完整详情
/// （`GET /api/goods/goodsInfo?goodsSn=...`）。
///
/// 列表接口只返回标题 / 价格 / 区服等摘要字段；详情接口才带全部商品图
/// （[images]）、商品描述（[description]）、亮点（[tags]）与卖家 / 上架时间等。
/// 分类字段按 `goodsTypeId` 填：账号类目用 [job] / [sex] / [level] /
/// [mainAtk] / [attr] / [attr2]，珍兽类目用 [petLevel] / [carryText] /
/// [ling] / [wu] / [locked]。
@immutable
class SxdsGoodsDetail {
  const SxdsGoodsDetail({
    required this.sn,
    required this.title,
    required this.price,
    this.goodsTypeId,
    this.goodsTypeName = '',
    this.area = '',
    this.server = '',
    this.areaId,
    this.serverId,
    // 账号类目
    this.job = '',
    this.sex = '',
    this.level = 0,
    this.mainAtk = '',
    this.attr = 0,
    this.attr2 = 0,
    // 珍兽类目
    this.petLevel = '',
    this.carryText = '',
    this.ling = '',
    this.wu = '',
    this.locked,
    // 通用
    this.views = 0,
    this.accountType = '',
    this.sourceName = '',
    this.seller = '',
    this.createdAt,
    this.updatedAt,
    this.canBargain,
    this.minBargainPrice,
    this.addPrice = 0,
    this.hasEnsure = false,
    this.description = '',
    this.tags = const [],
    this.images = const [],
  });

  /// 商品编号（账号 `TH…` / 珍兽 `BB…`）。
  final String sn;

  /// 商品标题（平台 `bigTitle`）。
  final String title;

  /// 售价（元）。
  final int price;

  /// 类目 id / 名称（1 = 游戏账号，25 = 宝宝）。
  final int? goodsTypeId;
  final String goodsTypeName;

  final String area;
  final String server;
  final int? areaId;
  final int? serverId;

  /// 账号：职业 / 性别 / 角色等级。
  final String job;
  final String sex;
  final int level;

  /// 账号：主属性攻（如 `主火攻`）+ 主属性 / 副属性数值。
  final String mainAtk;
  final int attr;
  final int attr2;

  /// 珍兽：宝宝等级（如 `95`）、可携带等级（如 `95级`）、灵性 / 悟性。
  final String petLevel;
  final String carryText;
  final String ling;
  final String wu;

  /// 珍兽：是否上锁（平台未标注时 null）。
  final bool? locked;

  final int views;

  /// 账号类型（平台 `zhanghaoName`，如「畅游账号登录」）。
  final String accountType;

  /// 商品来源（平台 `acSourceName`，如「神仙购买」）。
  final String sourceName;

  /// 卖家昵称（平台 `userName`）。
  final String seller;

  /// 上架 / 最近刷新时间。
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 是否可议价（平台未标注时为 null）；[minBargainPrice] 为最低议价（元）。
  final bool? canBargain;
  final int? minBargainPrice;

  /// 额外加价（元，平台 `addPrice`；通常为 0）。
  final int addPrice;

  /// 是否开通交易保障。
  final bool hasEnsure;

  /// 商品描述（平台 `goodsDecs`，保留原文换行）。
  final String description;

  /// 商品亮点（平台 `goodsTags` 拆分后的标签）。
  final List<String> tags;

  /// 全部商品图（完整 URL，已去重保序）。
  final List<String> images;

  /// 封面图（[images] 首张；无图时 null）。
  String? get cover => images.isEmpty ? null : images.first;
}
