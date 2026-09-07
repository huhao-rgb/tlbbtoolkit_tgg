/// 账号行情 —— 领域模型与数据（与原型 `ACC_DATA` / `AM_STATE` 一致）。
///
/// 数据抓取自神仙代售 sxds.com 怀旧服「游戏账号」类目公开在售列表，
/// 快照 2026-09-07，132 条样本。
library;

import 'package:flutter/foundation.dart';

/// 角色等级筛选档位 —— 与神仙代售平台筛选项（`roleLevelLimit`）一一对应：
///
/// | roleLevelLimit | 档位 | 说明 |
/// |---------------|------|------|
/// | （空）        | 全部等级 | 不按等级过滤 |
/// | 0-50          | 50级以下 | 0 ≤ lv < 50 |
/// | 50-60         | 50-59级  | 50 ≤ lv < 60 |
/// | 60-70         | 60-69级  | 60 ≤ lv < 70 |
/// | 70-80         | 70-79级  | 70 ≤ lv < 80 |
/// | 80-90         | 80-89级  | 80 ≤ lv < 90 |
/// | 90-100        | 90-99级  | 90 ≤ lv < 100 |
/// | 100-201       | 100级以上 | 100 ≤ lv（201 为平台封顶值） |
enum AccountLevelBand {
  all('全部等级', null),
  lt50('50级以下', '0-50'),
  s50('50-59级', '50-60'),
  s60('60-69级', '60-70'),
  s70('70-79级', '70-80'),
  s80('80-89级', '80-90'),
  s90('90-99级', '90-100'),
  ge100('100级以上', '100-201');

  const AccountLevelBand(this.label, this.limit);

  final String label;

  /// 平台 `roleLevelLimit` 参数（`min-max` 段位；null 表示「全部」）。
  final String? limit;

  /// 由平台 `roleLevelLimit` 字符串映射档位（如 '60-70' → s60）；未知返回 null。
  static AccountLevelBand? fromLimit(String? v) {
    if (v == null) return null;
    for (final b in AccountLevelBand.values) {
      if (b != AccountLevelBand.all && b.limit == v) return b;
    }
    return null;
  }
}

/// 一条在售账号快照（原型 ACC_DATA 元素）。
///
/// 字段与原型一一对应：`n` 编号、`t` 标题、`p` 价格、`v` 浏览量、
/// `a` 大区、`s` 服务器、`job` 职业、`sex` 性别、`lv` 等级、
/// `atk` 主攻、`attr` 主属性、`attr2` 副属性。真实平台还带
/// `areaId`/`serverId`（按区服重新拉取用）与 `img`（缩略图完整 URL）。
@immutable
class AccountListing {
  const AccountListing({
    required this.sn,
    required this.title,
    required this.price,
    required this.views,
    required this.area,
    required this.server,
    required this.job,
    required this.sex,
    required this.lv,
    required this.atk,
    required this.attr,
    this.attr2,
    this.areaId,
    this.serverId,
    this.img,
  });

  final String sn; // n 编号
  final String title; // t 标题
  final int price; // p 价格（元）
  final int views; // v 浏览量
  final String area; // a 大区
  final String server; // s 服务器
  final String job; // job 职业
  final String sex; // sex 性别
  final int lv; // lv 角色等级
  final String atk; // atk 主攻（如 '主玄攻'）
  final int attr; // attr 主属性
  final int? attr2; // attr2 副属性

  /// 平台大区 id（真实接口带，用于按区服重新拉取）。
  final int? areaId;

  /// 平台服务器 id（真实接口带，用于按区服重新拉取）。
  final int? serverId;

  /// 商品图完整 URL（真实接口 thumbnail 加 OSS 域名前缀；无则空）。
  final String? img;

  /// 主攻简写（'主玄攻' → '玄'，'主火攻' → '火'）。
  String get atkShort => atk.replaceAll('主', '').replaceAll('攻', '');

  /// 由原型快照 JSON 对象解析。
  factory AccountListing.fromJson(Map<String, dynamic> j) => AccountListing(
    sn: j['n'] as String? ?? '',
    title: j['t'] as String? ?? '',
    price: (j['p'] as num?)?.round() ?? 0,
    views: (j['v'] as num?)?.round() ?? 0,
    area: j['a'] as String? ?? '',
    server: j['s'] as String? ?? '',
    job: j['job'] as String? ?? '',
    sex: j['sex'] as String? ?? '',
    lv: (j['lv'] as num?)?.round() ?? 0,
    atk: j['atk'] as String? ?? '',
    attr: (j['attr'] as num?)?.round() ?? 0,
    attr2: (j['attr2'] as num?)?.round(),
    areaId: (j['areaId'] as num?)?.round(),
    serverId: (j['serverId'] as num?)?.round(),
    img: j['img'] as String?,
  );
}

/// 筛选状态（原型 `AM_STATE`）。
@immutable
class AccountMarketFilter {
  const AccountMarketFilter({
    this.area = '',
    this.server = '',
    this.band = AccountLevelBand.all,
  });

  final String area;
  final String server;
  final AccountLevelBand band;

  AccountMarketFilter copyWith({
    String? area,
    String? server,
    AccountLevelBand? band,
  }) => AccountMarketFilter(
    area: area ?? this.area,
    server: server ?? this.server,
    band: band ?? this.band,
  );
}
