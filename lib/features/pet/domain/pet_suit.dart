/// 珍兽套装图鉴 —— 领域模型与数据（天龙八部怀旧服 / 经典版「宝宝套」）。
///
/// 数据口径：按用户提供的《天龙八部珍兽套装明细——TLBB 工具包》表格逐格录入
/// （2026-11 核对；表头数值与 17173 / 52pk《珍兽套装全攻略（上 / 中 / 下篇）》、
/// 官方记者站攻略的兑换 / 升星 / 拆解口径一致）。
///
/// - 三档（75 / 85 / 95），**每档 9 个系列，共 27 套**，按「类型 + 性格」划分；
/// - 每套 5 件：珍兽面甲（头）/ 珍兽武器（爪）/ 珍兽体甲（躯干）/ 珍兽项圈（颈）/ 珍兽护符，
///   游戏内道具名为兽盔 / 兽爪 / 兽甲 / 兽环 / 兽饰；
/// - 每套有 5 列词条：套装自带词条、兽环属性、套装组合词条、套装技能增强效果、套装推荐说明；
/// - **全套只用一种材料：圣兽鳞**（兑换 1★ 与升星），由拆解珍兽套装获得，副本不直接掉落；
/// - 星级 1★~5★（5★ 为怀旧服上限）。
///
/// 圣兽鳞口径（表格表头）：
/// - 75 档：部件由煞星副本**直接掉落**（落地产出即 1★），全套五星需 130 个（纯升星）；
/// - 85 档：全套兑换 150 个，升星 390 个，合计 540 个；
/// - 95 档：全套兑换 500 个，升星 925 个，合计 1425 个。
/// 兑换 / 升星 / 拆解均可在苏州（248，184）云姗姗处完成，另有少量金钱消耗。
library;

import 'package:flutter/foundation.dart';

/// 套装档位（珍兽穿戴等级）：75 / 85 / 95。
const List<String> kSuitLvKeys = ['75', '85', '95'];

/// 标签配色（对应原型 `.tag-<catType>`）。
enum PetSuitCatColor { gold, cyan, green, blue, purple }

/// 一个珍兽套装系列（同一档位下按「类型 + 性格」划分）。
///
/// 用字与词条顺序照表格原文（含 95 档「内+命+会+灵」这类缩写写法，不做二次展开），
/// 只在数字 / 英文与汉字之间补空格，便于阅读。
@immutable
class PetSuitSeries {
  const PetSuitSeries({
    required this.name,
    required this.lv,
    required this.type,
    required this.typeColor,
    required this.icon,
    required this.personality,
    required this.ownEntries,
    required this.ringEntries,
    required this.comboEntries,
    required this.skillEffect,
    required this.recommendation,
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

  /// 套装自带词条（表格「套装自带词条」列，3~4 条，如「内功+会心」）。
  final String ownEntries;

  /// 兽环属性（表格「兽环属性」列，1~2 条，出战后生效，如「灵气+体力」）。
  final String ringEntries;

  /// 套装组合词条（表格「套装组合词条」列，穿齐 5 件生效，如「内功+命中+灵气」）。
  final String comboEntries;

  /// 套装技能增强效果（表格「套装技能增强效果」列，如「四咒伤害」）。
  final String skillEffect;

  /// 套装推荐说明（表格「套装推荐说明」列，含作者的主观建议）。
  final String recommendation;

  /// 适配文案，如「外功型 · 勇猛性格」。
  String get fitText => '$type型 · $personality性格';

  /// 表格里被作者标红劝退的套装（如「神坑！！一定不要选这个套」）。
  bool get discouraged => recommendation.contains('神坑');
}

/// 指定档位的系列清单（每档 9 套）。
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
/// 其中兽环（项圈）另有「出战后生效的系列专属属性」，
/// 其余部位提供散件基础属性（数值随星级提升）。
const List<PetSuitSlot> kPetSuitSlots = [
  PetSuitSlot(name: '兽盔', slot: '头', icon: 'part_helm', note: '散件基础属性'),
  PetSuitSlot(name: '兽爪', slot: '爪', icon: 'part_claw', note: '散件基础属性'),
  PetSuitSlot(name: '兽甲', slot: '躯干', icon: 'part_armor', note: '散件基础属性'),
  PetSuitSlot(name: '兽环', slot: '颈', icon: 'part_ring', note: '出战后附加系列专属属性'),
  PetSuitSlot(name: '兽饰', slot: '护符', icon: 'part_charm', note: '散件基础属性'),
];

/// 唯一材料名 —— 圣兽鳞（拆解珍兽套装获得，副本不直接掉落）。
const String kSuitMatName = '圣兽鳞';

/// 套装加成说明（表格表头三行说明 + 概率 / 伤害加成的口口相传经验值）。
const List<String> kSuitBonusNotes = [
  '75 套装：全套五星需 130 个圣兽鳞，煞星副本直接掉落部件',
  '85 套装：全套兑换需 150 个，全套 5 星升星共 390 个（合计 540 个）',
  '95 套装：全套兑换需 500 个圣兽鳞，全套 5 星升星共 925 个（合计 1425 个）',
  '概率加成（作者体感）：1 星套装额外加成 5% 触发概率，随后每提升 1 星提高 5%，'
      '5 星套装共计提升 25%；不同技能加成比例可能有差别。',
  '伤害加成：猛击套和痛击套为增伤加成，不享受基础暴击，但会享受拼命的额外暴击倍率；'
      '1 星增伤 2000，随后每 1 星增加 1400，5 星套累计增伤 7600，打怪伤害 ×5，即 5 星 38000。',
];

/// 某档位的圣兽鳞消耗（均为「每件」口径）。
@immutable
class SuitMatCost {
  const SuitMatCost({
    required this.exchange,
    required this.starUp,
    required this.salvage,
  });

  /// 兑换 1★ 部件所需（每件）；75 档部件由煞星副本直接掉落，兑换消耗为 0。
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
///
/// 与表格表头一致：75 档 130 / 85 档 150 + 390 / 95 档 500 + 925（均为整套 5 件口径）。
const Map<String, SuitMatCost> kSuitMatCost = {
  // 75 档：部件由煞星副本直接掉落（1★），无需兑换；升星 3 / 5 / 7 / 11，
  // 每件升满 5★ 共 26 个，一套 5 件 130 个。
  '75': SuitMatCost(
    exchange: 0,
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

/// 27 个珍兽套装系列（75 / 85 / 95 档各 9 套）。
///
/// 顺序照表格：内功（怯 / 狡 / 慎）→ 外功（勇 / 狡 / 慎）→ 体力（忠 / 慎）→ 身法（慎）。
const List<PetSuitSeries> kPetSuitSeries = [
  // ---------------- 75 档（9 套） ----------------
  PetSuitSeries(
    name: '黄雀戏水·怯',
    lv: '75',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '胆小',
    ownEntries: '内功+会心',
    ringEntries: '灵气+体力',
    comboEntries: '内功+命中+灵气',
    skillEffect: '四咒伤害',
    recommendation: '内功宝宝入门选择',
  ),
  PetSuitSeries(
    name: '黄雀戏水·狡',
    lv: '75',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '精明',
    ownEntries: '内功+命中',
    ringEntries: '命中+会心',
    comboEntries: '命中+血上限+灵气',
    skillEffect: '摔绊释放几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '黄雀戏水·慎',
    lv: '75',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '谨慎',
    ownEntries: '血上限+命中',
    ringEntries: '灵气+身法',
    comboEntries: '命中+血上限+灵气',
    skillEffect: '虚弱释放几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '苍狼啸月·勇',
    lv: '75',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '勇猛',
    ownEntries: '外功+会心',
    ringEntries: '力量+体力',
    comboEntries: '外功+命中+力量',
    skillEffect: '猛击伤害',
    recommendation: '一星增加约 10000 打怪伤害，每提高一星增加 7000，5 星合计 38000，外功宝宝初级毕业套',
  ),
  PetSuitSeries(
    name: '苍狼啸月·狡',
    lv: '75',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '精明',
    ownEntries: '外功+命中',
    ringEntries: '命中+会心',
    comboEntries: '命中+血上限+力量',
    skillEffect: '摔绊释放几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '苍狼啸月·慎',
    lv: '75',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '谨慎',
    ownEntries: '血上限+命中',
    ringEntries: '力量+身法',
    comboEntries: '命中+血上限+力量',
    skillEffect: '虚弱释放几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '乌鹏望日·忠',
    lv: '75',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '忠诚',
    ownEntries: '内外防',
    ringEntries: '体力',
    comboEntries: '内外防+血上限',
    skillEffect: '灵动触发概率',
    recommendation: '体力宝宝入门选择',
  ),
  PetSuitSeries(
    name: '乌鹏望日·慎',
    lv: '75',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '谨慎',
    ownEntries: '血上限+命中',
    ringEntries: '体力+身法',
    comboEntries: '身法+命中+血上限',
    skillEffect: '虚弱释放几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '白兔隐林·慎',
    lv: '75',
    type: '身法',
    typeColor: PetSuitCatColor.cyan,
    icon: 'pct',
    personality: '谨慎',
    ownEntries: '命中+闪避',
    ringEntries: '身法',
    comboEntries: '命中+身法+血上限',
    skillEffect: '虚弱释放几率',
    recommendation: '基本用不着',
  ),

  // ---------------- 85 档（9 套） ----------------
  PetSuitSeries(
    name: '飞鹰翔空·怯',
    lv: '85',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '胆小',
    ownEntries: '内功+命+会',
    ringEntries: '灵气+体力',
    comboEntries: '内功+命中+灵气',
    skillEffect: '痛击伤害',
    recommendation: '增加痛击打怪伤害 38000（和 75 勇猛套同理），胆小 / 谨慎内功宝宝初级毕业套',
  ),
  PetSuitSeries(
    name: '飞鹰翔空·狡',
    lv: '85',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '精明',
    ownEntries: '血+内功+命',
    ringEntries: '命中+会心',
    comboEntries: '命中+血上限+灵气',
    skillEffect: '反震生效几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '飞鹰翔空·慎',
    lv: '85',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '谨慎',
    ownEntries: '血+命中+身',
    ringEntries: '灵气+身法',
    comboEntries: '命中+血上限+灵气',
    skillEffect: '吸气生效几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '猛虎越山·勇',
    lv: '85',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '勇猛',
    ownEntries: '外功+命+会',
    ringEntries: '力量+体力',
    comboEntries: '外功+命中+力量',
    skillEffect: '猛击释放几率',
    recommendation: '神坑！！一定不要选这个套',
  ),
  PetSuitSeries(
    name: '猛虎越山·狡',
    lv: '85',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '精明',
    ownEntries: '血+外+命',
    ringEntries: '命中+会心',
    comboEntries: '命中+血上限+力量',
    skillEffect: '反震生效几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '猛虎越山·慎',
    lv: '85',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '谨慎',
    ownEntries: '血+命+身',
    ringEntries: '力量+身法',
    comboEntries: '命中+血上限+力量',
    skillEffect: '吸气生效几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '巨熊踏路·忠',
    lv: '85',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '忠诚',
    ownEntries: '内外防+闪',
    ringEntries: '体力',
    comboEntries: '内外防+血上限',
    skillEffect: '忠心生效几率',
    recommendation: '基本用不着',
  ),
  PetSuitSeries(
    name: '巨熊踏路·慎',
    lv: '85',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '谨慎平衡',
    ownEntries: '命+闪+身',
    ringEntries: '体力+身法',
    comboEntries: '身法+命中+血上限',
    skillEffect: '吸气生效几率',
    recommendation: '吸气宝宝可选',
  ),
  PetSuitSeries(
    name: '奔马逐风·慎',
    lv: '85',
    type: '身法',
    typeColor: PetSuitCatColor.cyan,
    icon: 'pct',
    personality: '谨慎平衡',
    ownEntries: '命+闪+身',
    ringEntries: '身法',
    comboEntries: '命中+身法+血上限',
    skillEffect: '吸气生效几率',
    recommendation: '吸气宝宝可选',
  ),

  // ---------------- 95 档（9 套） ----------------
  PetSuitSeries(
    name: '鲲鹏异羽·怯',
    lv: '95',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '胆小',
    ownEntries: '内+命+会+灵',
    ringEntries: '灵气+体力',
    comboEntries: '内功+命中+灵气',
    skillEffect: '四咒释放几率',
    recommendation: '高资质全性格内功毕业套',
  ),
  PetSuitSeries(
    name: '鲲鹏异羽·狡',
    lv: '95',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '精明',
    ownEntries: '血+内+命+灵',
    ringEntries: '命中+会心',
    comboEntries: '命中+血上限+灵气',
    skillEffect: '反击生效几率',
    recommendation: '精明单刷或者 PK 可选，一般用不到',
  ),
  PetSuitSeries(
    name: '鲲鹏异羽·慎',
    lv: '95',
    type: '内功',
    typeColor: PetSuitCatColor.blue,
    icon: 'spark',
    personality: '谨慎',
    ownEntries: '血+命+身+灵',
    ringEntries: '灵气+身法',
    comboEntries: '命中+血上限+灵气',
    skillEffect: '打怒生效几率',
    recommendation: 'PK 可以考虑，加血比较多',
  ),
  PetSuitSeries(
    name: '雄狮逆鳞·勇',
    lv: '95',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '勇猛',
    ownEntries: '外+命+会+力',
    ringEntries: '力量+体力',
    comboEntries: '外功+命中+力量',
    skillEffect: '连击释放几率',
    recommendation: '高资质全性格外功毕业套',
  ),
  PetSuitSeries(
    name: '雄狮逆鳞·狡',
    lv: '95',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '精明',
    ownEntries: '血+外+命+力',
    ringEntries: '命中+会心',
    comboEntries: '命中+血上限+力量',
    skillEffect: '反击生效几率',
    recommendation: '精明单刷或者 PK 可选，一般用不到',
  ),
  PetSuitSeries(
    name: '雄狮逆鳞·慎',
    lv: '95',
    type: '外功',
    typeColor: PetSuitCatColor.gold,
    icon: 'sword',
    personality: '谨慎',
    ownEntries: '血+命+身+力',
    ringEntries: '力量+身法',
    comboEntries: '命中+血上限+力量',
    skillEffect: '打怒生效几率',
    recommendation: 'PK 可以考虑，加血比较多',
  ),
  PetSuitSeries(
    name: '玄龟奇血·忠',
    lv: '95',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '忠诚',
    ownEntries: '内外防+闪+体',
    ringEntries: '体力',
    comboEntries: '内外防+血上限',
    skillEffect: '灵气生效几率',
    recommendation: '忠诚体力毕业套',
  ),
  PetSuitSeries(
    name: '玄龟奇血·慎',
    lv: '95',
    type: '体力',
    typeColor: PetSuitCatColor.green,
    icon: 'shield',
    personality: '谨慎平衡',
    ownEntries: '血+命+闪+身',
    ringEntries: '体力+身法',
    comboEntries: '身法+命中+血上限',
    skillEffect: '打怒生效几率',
    recommendation: '谨慎+精明体力毕业套',
  ),
  PetSuitSeries(
    name: '墨豹惊山·慎',
    lv: '95',
    type: '身法',
    typeColor: PetSuitCatColor.cyan,
    icon: 'pct',
    personality: '谨慎平衡',
    ownEntries: '血+命+闪+身',
    ringEntries: '身法',
    comboEntries: '命中+身法+血上限',
    skillEffect: '打怒生效几率',
    recommendation: '身法宝宝毕业套',
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
/// - 兑换：每件 [SuitMatCost.exchange]（1★ 装备），整套按 5 件；75 档为 0（副本掉落）；
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
