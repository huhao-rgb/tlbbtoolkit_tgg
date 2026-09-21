/// 珍兽套装图鉴 —— 领域模型与数据（天龙八部怀旧服 / 经典版「宝宝套」）。
///
/// 怀旧服的珍兽套装即 2009 年随「十二煞星」加入的宝宝套，数值与经典版一致：
/// - 三档（75 / 85 / 95），**每档是独立的一批系列**，同名系列不跨档复用；
/// - 22 个系列：75 档 4 套、85 档 9 套、95 档 9 套，按「类型 + 性格」划分；
/// - 每套 5 件：珍兽面甲（头）/ 珍兽武器（爪）/ 珍兽体甲（躯干）/ 珍兽项圈（颈）/ 珍兽护符；
/// - **全套只用一种材料：圣兽鳞**（兑换 1★ 与升星），由拆解珍兽套装获得，副本不直接掉落；
/// - 星级 1★~5★（5★ 为怀旧服上限），另有少量金钱消耗（本页只计圣兽鳞）。
///
/// 数据来源（2026-09 核对，均为怀旧服 / 经典版口径）：
/// - 畅游官方「珍兽装备」资料：五部位构成、NPC（苏州 248,184 云姗姗）、圣兽鳞用途。
/// - 经典怀旧·新天龙八部官网「游戏资料 · 珍兽装备」：杀星副本与套装星级提升。
/// - 17173《珍兽套装全攻略（上 / 中 / 下篇）》：22 个系列名、全套效果与兑换 / 升星 / 拆解数值。
/// - 17173 怀旧服攻略：确认怀旧服沿用同一套数值（如 75 档升满 5 星共 130 个圣兽鳞）。
library;

import 'package:flutter/foundation.dart';

/// 套装档位（珍兽穿戴等级）：75 / 85 / 95。
const List<String> kSuitLvKeys = ['75', '85', '95'];

/// 标签配色（对应原型 `.tag-<catType>`）。
enum PetSuitCatColor { gold, cyan, green, blue, purple }

/// 一个珍兽套装系列（同一档位下按「类型 + 性格」划分）。
@immutable
class PetSuitSeries {
  const PetSuitSeries({
    required this.name,
    required this.lv,
    required this.type,
    required this.typeColor,
    required this.icon,
    required this.personality,
    required this.fullEffect,
    this.stats = const <String>[],
    this.collar,
  });

  /// 系列名，如「苍狼啸月·勇」。
  final String name;

  /// 档位（75 / 85 / 95），即该套装的珍兽穿戴等级要求。
  final String lv;

  /// 类型：外功 / 内功 / 体力 / 身法。
  final String type;

  /// 类型 tag 配色。
  final PetSuitCatColor typeColor;

  /// 图标资产名（经 `TgIcon` 渲染，如 `sword`）。
  final String icon;

  /// 适配性格：勇猛 / 精明 / 谨慎 / 胆小 / 忠诚 / 谨慎平衡。
  final String personality;

  /// 穿齐 5 件的全套效果。
  final String fullEffect;

  /// 散件属性方向（官方资料仅 75 档逐系列列出，其余为空）。
  final List<String> stats;

  /// 项圈出战效果（官方资料未列出时为空）。
  final String? collar;

  /// 适配文案，如「外功型 · 勇猛性格」。
  String get fitText => '$type型 · $personality性格';
}

/// 指定档位的系列清单（75 → 4 套 / 85 → 9 套 / 95 → 9 套）。
List<PetSuitSeries> petSuitsAt(String lv) =>
    kPetSuitSeries.where((s) => s.lv == lv).toList(growable: false);

/// 五件套中的一个部位。
@immutable
class PetSuitSlot {
  const PetSuitSlot({
    required this.name,
    required this.slot,
    required this.icon,
    required this.note,
  });

  /// 游戏内部位名：兽盔 / 兽爪 / 兽甲 / 兽环 / 兽饰。
  final String name;

  /// 部位简称：头 / 爪 / 躯干 / 颈 / 护符。
  final String slot;

  /// 部位图标资产名（`assets/pet_suit/<icon>.png`，取自游戏内珍兽装备图鉴截图）。
  final String icon;

  /// 部位说明。
  final String note;
}

/// 五个部位（顺序：兽盔 / 兽爪 / 兽甲 / 兽环 / 兽饰）。
///
/// 部位名取自游戏内道具名（官方资料里对应写作珍兽面甲 / 武器 / 体甲 / 项圈 / 护符）；
/// 其中兽环（项圈）另有「出战后生效的系列专属效果」，其余部位提供散件基础属性
/// （数值随星级提升）。
const List<PetSuitSlot> kPetSuitSlots = [
  PetSuitSlot(name: '兽盔', slot: '头', icon: 'part_helm', note: '散件基础属性'),
  PetSuitSlot(name: '兽爪', slot: '爪', icon: 'part_claw', note: '散件基础属性'),
  PetSuitSlot(name: '兽甲', slot: '躯干', icon: 'part_armor', note: '散件基础属性'),
  PetSuitSlot(name: '兽环', slot: '颈', icon: 'part_ring', note: '出战后附加系列专属效果'),
  PetSuitSlot(name: '兽饰', slot: '护符', icon: 'part_charm', note: '散件基础属性'),
];

/// 唯一材料名 —— 圣兽鳞（拆解珍兽套装获得，副本不直接掉落）。
const String kSuitMatName = '圣兽鳞';

/// 某档位的圣兽鳞消耗（均为「每件」口径）。
@immutable
class SuitMatCost {
  const SuitMatCost({
    required this.exchange,
    required this.starUp,
    required this.salvage,
  });

  /// 兑换 1★ 部件所需（每件）；75 档也可由煞星副本掉落。
  final int exchange;

  /// 每件由 k★ 升到 (k+1)★ 所需：下标 0 为 1★→2★。
  final List<int> starUp;

  /// 每件 k★ 拆解返还的圣兽鳞：下标 0 为 1★。
  final List<int> salvage;

  /// 每件升到 [star] 星的累计圣兽鳞（1★ 即兑换消耗）。
  int perPieceTo(int star) {
    var n = exchange;
    for (var k = 2; k <= star; k++) {
      n += starUp[k - 2];
    }
    return n;
  }
}

/// 各档位圣兽鳞消耗表（每件）。
const Map<String, SuitMatCost> kSuitMatCost = {
  // 75 档：兑换 1 个（该档部件主要来自煞星副本掉落，落地产出为 1★）；
  // 升星 3 / 5 / 7 / 11 → 每件升满 5★ 共 27 个，一套 5 件 135 个。
  '75': SuitMatCost(
    exchange: 1,
    starUp: [3, 5, 7, 11],
    salvage: [1, 3, 7, 12, 20],
  ),
  // 85 档：兑换 30 个；升星 16 / 18 / 20 / 24 → 每件升满 5★ 共 108 个，一套 5 件 540 个。
  '85': SuitMatCost(
    exchange: 30,
    starUp: [16, 18, 20, 24],
    salvage: [20, 30, 35, 42, 57],
  ),
  // 95 档：兑换 100 个；升星 36 / 43 / 50 / 56 → 每件升满 5★ 共 285 个，一套 5 件 1425 个。
  '95': SuitMatCost(
    exchange: 100,
    starUp: [36, 43, 50, 56],
    salvage: [50, 68, 90, 115, 143],
  ),
};

/// 22 个珍兽套装系列（75 档 4 套 + 85 档 9 套 + 95 档 9 套）。
///
/// 系列名 / 适配性格 / 项圈效果 / 全套效果照 17173《新版：珍兽套装全攻略（上 / 中 / 下篇）》
/// 原文整理；75 档的散件属性方向取自同批资料。
const List<PetSuitSeries> kPetSuitSeries = [
  // ---------------- 75 档（4 套） ----------------
  PetSuitSeries(
    name: '黄雀戏水·怯',
    lv: '75',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '胆小',
    stats: ['内功攻击', '灵气', '命中'],
    fullEffect: '烈火咒 / 玄雷咒 / 血毒咒 / 寒冰咒释放时额外增加对应属性攻击',
    collar: '提升灵气、体力',
  ),
  PetSuitSeries(
    name: '苍狼啸月·勇',
    lv: '75',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '勇猛',
    stats: ['外功攻击', '力量', '命中'],
    fullEffect: '猛击技能释放时额外增加外功攻击',
    collar: '提升体力',
  ),
  PetSuitSeries(
    name: '苍狼啸月·狡',
    lv: '75',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '精明',
    stats: ['外功攻击', '力量', '血上限'],
    fullEffect: '增加摔绊技能对目标的生效几率',
  ),
  PetSuitSeries(
    name: '乌豚望日·忠',
    lv: '75',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '忠诚',
    stats: ['内外功防御', '血上限'],
    fullEffect: '增加灵动技能对珍兽的生效几率',
    collar: '提升体力',
  ),

  // ---------------- 85 档（9 套） ----------------
  PetSuitSeries(
    name: '猛虎越山·勇',
    lv: '85',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '勇猛',
    fullEffect: '增加猛击技能的释放几率',
    collar: '提升力量、体力',
  ),
  PetSuitSeries(
    name: '猛虎越山·狡',
    lv: '85',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '精明',
    fullEffect: '增加反震技能的生效几率',
    collar: '提升命中、会心攻击',
  ),
  PetSuitSeries(
    name: '猛虎越山·慎',
    lv: '85',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '谨慎',
    fullEffect: '增加吸气技能的生效几率',
    collar: '提升力量、体力',
  ),
  PetSuitSeries(
    name: '飞鹰翔空·狡',
    lv: '85',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '精明',
    fullEffect: '增加反震技能的生效几率',
    collar: '提升命中、会心攻击',
  ),
  PetSuitSeries(
    name: '飞鹰翔空·怯',
    lv: '85',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '胆小',
    fullEffect: '增加痛击技能的伤害',
    collar: '提升灵气、体力',
  ),
  PetSuitSeries(
    name: '飞鹰翔空·慎',
    lv: '85',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '谨慎',
    fullEffect: '增加吸气技能的释放几率',
    collar: '提升灵气、身法',
  ),
  PetSuitSeries(
    name: '巨熊哮路·忠',
    lv: '85',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '忠诚',
    fullEffect: '增加忠心技能的生效几率',
    collar: '提升体力',
  ),
  PetSuitSeries(
    name: '巨熊哮路·慎',
    lv: '85',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '谨慎平衡',
    fullEffect: '增加吸气技能的生效几率',
    collar: '提升体力、身法',
  ),
  PetSuitSeries(
    name: '奔马逐风·慎',
    lv: '85',
    type: '身法',
    typeColor: PetSuitCatColor.cyan,
    icon: 'pct',
    personality: '谨慎平衡',
    fullEffect: '增加吸气技能的生效几率',
    collar: '提升身法',
  ),

  // ---------------- 95 档（9 套） ----------------
  PetSuitSeries(
    name: '雄狮逆鳞·勇',
    lv: '95',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '勇猛',
    fullEffect: '增加连击技能的释放几率',
    collar: '提升力量、体力',
  ),
  PetSuitSeries(
    name: '雄狮逆鳞·狡',
    lv: '95',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '精明',
    fullEffect: '增加反击技能的生效几率',
    collar: '提升命中、会心攻击',
  ),
  PetSuitSeries(
    name: '雄狮逆鳞·慎',
    lv: '95',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '谨慎',
    fullEffect: '增加打怒技能的生效几率',
    collar: '提升力量、身法',
  ),
  PetSuitSeries(
    name: '鲲鹏异羽·狡',
    lv: '95',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '精明',
    fullEffect: '增加反击技能的生效几率',
    collar: '提升命中、会心攻击',
  ),
  PetSuitSeries(
    name: '鲲鹏异羽·怯',
    lv: '95',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '胆小',
    fullEffect: '增加烈火咒 / 寒冰咒 / 玄雷咒 / 血毒咒技能的释放几率',
    collar: '提升灵气、体力',
  ),
  PetSuitSeries(
    name: '鲲鹏异羽·慎',
    lv: '95',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '谨慎',
    fullEffect: '增加打怒技能的释放几率',
    collar: '提升灵气、身法',
  ),
  PetSuitSeries(
    name: '玄龟奇血·忠',
    lv: '95',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '忠诚',
    fullEffect: '增加灵气技能的生效几率',
    collar: '提升体力',
  ),
  PetSuitSeries(
    name: '玄龟奇血·慎',
    lv: '95',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '谨慎平衡',
    fullEffect: '增加打怒技能的生效几率',
    collar: '提升体力、身法',
  ),
  PetSuitSeries(
    name: '墨豹惊步·慎',
    lv: '95',
    type: '身法',
    typeColor: PetSuitCatColor.cyan,
    icon: 'pct',
    personality: '谨慎平衡',
    fullEffect: '增加打怒技能的生效几率',
    collar: '提升身法',
  ),
];

/// 材料计算输入。
@immutable
class SuitMatCalcInput {
  const SuitMatCalcInput({
    required this.lv,
    required this.targetStar,
    required this.withExchange,
  });

  /// 档位（75 / 85 / 95）。
  final String lv;

  /// 目标星级（1★~5★）：1★ 只需兑换 1★ 整套，5★ 为兑换 + 逐星升满。
  final int targetStar;

  /// 是否计入兑换 1★ 整套的材料（已有 1★ 部件时可关闭）。
  final bool withExchange;
}

/// 单次升星消耗（每件 / 整套 5 件）。
@immutable
class SuitMatStarRow {
  const SuitMatStarRow({
    required this.star,
    required this.perPiece,
    required this.setTotal,
  });

  /// 目标星级（2~5）。
  final int star;

  /// 每件消耗。
  final int perPiece;

  /// 整套（5 件）消耗。
  final int setTotal;
}

/// 材料计算结果（单位：圣兽鳞）。
@immutable
class SuitMatCalcResult {
  const SuitMatCalcResult({
    required this.lv,
    required this.targetStar,
    required this.exchangePerPiece,
    required this.exchangeSet,
    required this.starRows,
    required this.upgradeSet,
    required this.total,
    required this.salvagePerPiece,
    required this.fullSetTotal,
  });

  /// 档位。
  final String lv;

  /// 目标星级（1★~5★）。
  final int targetStar;

  /// 兑换 1★ 的每件消耗。
  final int exchangePerPiece;

  /// 兑换 1★ 整套（5 件）消耗；不计入兑换时为 0。
  final int exchangeSet;

  /// 升到目标星级的逐星消耗（2★ 起；目标 1★ 时为空）。
  final List<SuitMatStarRow> starRows;

  /// 升星合计（5 件）。
  final int upgradeSet;

  /// 合计 = 兑换 + 升星。
  final int total;

  /// 各星级每件拆解返还（下标 0 为 1★）。
  final List<int> salvagePerPiece;

  /// 该档位「兑换 1★ + 升满 5★」整套（5 件）参考值。
  final int fullSetTotal;
}

/// 计算做到目标星级所需的圣兽鳞（怀旧服口径）：
/// - 兑换：每件 [SuitMatCost.exchange]（1★ 装备），整套按 5 件；
/// - 升星：1★ → [SuitMatCalcInput.targetStar]，逐星「每件消耗 × 5 件」，目标 1★ 时无升星行。
SuitMatCalcResult suitMatsCalc(SuitMatCalcInput input) {
  final cost = kSuitMatCost[input.lv] ?? kSuitMatCost[kSuitLvKeys.first]!;
  final exchangeSet = input.withExchange ? cost.exchange * 5 : 0;

  // 目标星级取值 1★~5★（越界值按边界处理）。
  final target = input.targetStar.clamp(1, 5);
  final rows = <SuitMatStarRow>[];
  for (var k = 2; k <= target; k++) {
    final perPiece = cost.starUp[k - 2];
    rows.add(
      SuitMatStarRow(star: k, perPiece: perPiece, setTotal: perPiece * 5),
    );
  }
  final upgradeSet = rows.fold<int>(0, (sum, r) => sum + r.setTotal);

  return SuitMatCalcResult(
    lv: input.lv,
    targetStar: target,
    exchangePerPiece: cost.exchange,
    exchangeSet: exchangeSet,
    starRows: rows,
    upgradeSet: upgradeSet,
    total: exchangeSet + upgradeSet,
    salvagePerPiece: cost.salvage,
    fullSetTotal: cost.perPieceTo(5) * 5,
  );
}
