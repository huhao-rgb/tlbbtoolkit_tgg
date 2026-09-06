/// 珍兽行情 —— 领域模型与数据（与原型 `PET_DATA` / `PM_STATE` 一致）。
///
/// 数据抓取自神仙代售 sxds.com 怀旧原始服「宝宝」类目公开在售列表，
/// 快照 2026-09-05，15 页 176 条样本。
library;

import 'package:flutter/foundation.dart';

/// 可携带等级筛选档位 —— 与神仙代售平台筛选项（`packId`）一一对应：
///
/// | packId | 档位 | 说明 |
/// |-------|------|------|
/// | 52 | 95级 | 珍兽可携带等级 95 |
/// | 53 | 85级 | 珍兽可携带等级 85 |
/// | 54 | 75级 | 珍兽可携带等级 75 |
/// | 55 | 65级 | 珍兽可携带等级 65 |
/// | 56 | 其他等级 | 其余（45/55/105+ 等） |
///
/// 原型用连续数值段（0-65/66-89/90-95/96-105/106+）过滤 `cl||lv`；
/// 真实平台是上述离散档位，本枚举以平台档位为准。
enum PetCarryBand {
  all('全部等级', 0),
  p95('95级', 52),
  p85('85级', 53),
  p75('75级', 54),
  p65('65级', 55),
  other('其他等级', 56);

  const PetCarryBand(this.label, this.packId);

  final String label;

  /// 平台筛选项 id（0 表示「全部」占位）。
  final int packId;

  /// 由真实平台 `packId`（52-56）映射档位；未知返回 null。
  static PetCarryBand? fromPackId(int id) {
    switch (id) {
      case 52:
        return p95;
      case 53:
        return p85;
      case 54:
        return p75;
      case 55:
        return p65;
      case 56:
        return other;
      default:
        return null;
    }
  }

  /// 由平台档位文本（`packName`，如 "95级"/"其他等级"，可含空格）映射档位。
  static PetCarryBand? fromPackName(String? name) {
    if (name == null) return null;
    final n = name.replaceAll(RegExp(r'\s+'), '');
    for (final b in PetCarryBand.values) {
      if (b != PetCarryBand.all && b.label == n) return b;
    }
    return null;
  }

  /// 由数字近似归档（快照无 packId/packName 时的兜底）。
  ///
  /// 规则（演示快照）：≤65→65级、66-75→75级、76-85→85级、86-95→95级、
  /// 其余（0 或 >95）→ 其他等级。
  static PetCarryBand fromLevel(int v) {
    if (v <= 0) return other;
    if (v <= 65) return p65;
    if (v <= 75) return p75;
    if (v <= 85) return p85;
    if (v <= 95) return p95;
    return other;
  }
}

/// 一条在售商品快照（原型 PET_DATA 元素）。
///
/// 字段与原型一一对应：`t` 标题、`p` 价格、`a` 大区、`s` 服务器、
/// `lv` 等级、`lx` 灵性、`wx` 悟性、`pet` 品种、`ch` 性格、`apt` 资质、
/// `ss` 双十、`ding` 顶变、`sk` 技能全、`cl` 可携带等级、`v` 浏览量、`sn` 编号。
/// 真实平台还带 `packId`/`packName`（可携带等级档位，权威）。
@immutable
class PetListing {
  const PetListing({
    required this.title,
    required this.price,
    required this.area,
    required this.server,
    required this.lv,
    required this.ling,
    required this.wu,
    required this.pet,
    required this.ch,
    required this.apt,
    required this.ss,
    required this.ding,
    required this.skill,
    required this.carry,
    required this.views,
    required this.sn,
    this.areaId,
    this.serverId,
    this.packId,
    this.packName,
    this.img,
  });

  final String title; // t
  final int price; // p（元）
  final String area; // a 大区
  final String server; // s 服务器
  final int lv; // lv 等级
  final String ling; // lx 灵性（'0' 表示未标注）
  final String wu; // wx 悟性
  final String pet; // pet 品种（'其他' 视为无品种）
  final String? ch; // ch 性格
  final int? apt; // apt 资质
  final bool ss; // ss 双十
  final bool ding; // ding 顶变
  final int? skill; // sk 技能全 n
  final int? carry; // cl 可携带等级（快照数字兜底）
  final int views; // v 浏览量
  final String sn; // sn 编号

  /// 商品图完整 URL（真实接口 thumbnail 加 OSS 域名前缀；无则空）。
  final String? img;

  /// 平台大区 id（真实接口带，用于按区服重新拉取）。
  final int? areaId;

  /// 平台服务器 id（真实接口带，用于按区服重新拉取）。
  final int? serverId;

  /// 平台可携带等级档位 id（52=95级/53=85级/54=75级/55=65级/56=其他）。
  final int? packId;

  /// 平台可携带等级档位文本（如 "95级"/"其他等级"）。
  final String? packName;

  /// 携带等级 = cl 或 lv（原型 `pmCarry`，数字兜底）。
  int get carryLevel => carry ?? lv;

  /// 归档档位：真实 packId/packName 优先，否则快照数字近似。
  PetCarryBand get band {
    if (packId != null) {
      final b = PetCarryBand.fromPackId(packId!);
      if (b != null) return b;
    }
    if (packName != null && packName!.isNotEmpty) {
      final b = PetCarryBand.fromPackName(packName);
      if (b != null) return b;
    }
    return PetCarryBand.fromLevel(carryLevel);
  }

  /// 展示用档位文本（如 "95级"/"其他等级"）。
  String get carryText => band.label;

  /// 由原型快照 JSON 对象解析。
  factory PetListing.fromJson(Map<String, dynamic> j) => PetListing(
    title: j['t'] as String? ?? '',
    price: (j['p'] as num?)?.round() ?? 0,
    area: j['a'] as String? ?? '',
    server: j['s'] as String? ?? '',
    lv: (j['lv'] as num?)?.round() ?? 0,
    ling: j['lx'] as String? ?? '0',
    wu: j['wx'] as String? ?? '0',
    pet: j['pet'] as String? ?? '其他',
    ch: j['ch'] as String?,
    apt: (j['apt'] as num?)?.round(),
    ss: j['ss'] == true,
    ding: j['ding'] == true,
    skill: (j['sk'] as num?)?.round(),
    carry: (j['cl'] as num?)?.round(),
    views: (j['v'] as num?)?.round() ?? 0,
    sn: j['sn'] as String? ?? '',
    areaId: (j['areaId'] as num?)?.round(),
    serverId: (j['serverId'] as num?)?.round(),
    packId: (j['packId'] as num?)?.round(),
    packName: j['packName'] as String?,
    img: j['img'] as String?,
  );
}

/// 筛选状态（原型 `PM_STATE`）。
@immutable
class PetMarketFilter {
  const PetMarketFilter({
    this.area = '',
    this.server = '',
    this.carryBand = PetCarryBand.all,
  });

  final String area;
  final String server;
  final PetCarryBand carryBand;

  PetMarketFilter copyWith({
    String? area,
    String? server,
    PetCarryBand? carryBand,
  }) => PetMarketFilter(
    area: area ?? this.area,
    server: server ?? this.server,
    carryBand: carryBand ?? this.carryBand,
  );
}
