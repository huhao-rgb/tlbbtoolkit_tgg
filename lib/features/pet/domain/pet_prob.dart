/// 珍兽技能发动概率 —— 领域模型与公式。
///
/// 口径来源：玩家整理的《天龙八部珍兽性格 / 技能发动概率》表。
/// - 每个技能有自身的「基础概率」（生效几率，如下表 20 / 30 / 7 / 12 …）；
/// - 性格对五系技能（物攻 / 法攻 / 护主 / 防御 / 报复）给出不同「发动系数」；
/// - 发动概率 = min(100, round(基础概率 × 发动系数))。
///
/// 系数表（行 = 技能系，列 = 性格）：
///
/// |        | 胆小 | 谨慎 | 忠诚 | 精明 | 勇猛 |
/// | ------ | ---- | ---- | ---- | ---- | ---- |
/// | 物攻   | 0.5  | 0.8  | 1    | 1.3  | 2    |
/// | 法攻   | 2    | 1.3  | 1    | 0.8  | 0.5  |
/// | 护主   | 0.5  | 1.3  | 2    | 1    | 0.8  |
/// | 防御   | 1    | 2    | 1    | 0.8  | 0.5  |
/// | 报复   | 0.5  | 0.8  | 1    | 2    | 1.3  |
library;

import 'package:flutter/foundation.dart';

/// 技能系 —— 决定性格发动系数（对应概率表的 5 行）。
enum PetSkillFamily { physical, magic, guard, defense, revenge }

extension PetSkillFamilyX on PetSkillFamily {
  /// 系名（如「物攻」）。
  String get label => switch (this) {
    PetSkillFamily.physical => '物攻',
    PetSkillFamily.magic => '法攻',
    PetSkillFamily.guard => '护主',
    PetSkillFamily.defense => '防御',
    PetSkillFamily.revenge => '报复',
  };

  /// 该系的代表技能（概率表原文），用于页面注脚与详情弹窗。
  String get members => switch (this) {
    PetSkillFamily.physical => '猛击、连击',
    PetSkillFamily.magic => '四咒、痛击',
    PetSkillFamily.guard => '忠心、灵气',
    PetSkillFamily.defense => '破绽、虚弱、打怒、灵动、吸气',
    PetSkillFamily.revenge => '反击、反震、摔绊',
  };

  /// 该系 tag 颜色：物攻金 / 法攻青 / 护主绿 / 防御蓝 / 报复红。
  PetTagColor get tagColor => switch (this) {
    PetSkillFamily.physical => PetTagColor.gold,
    PetSkillFamily.magic => PetTagColor.cyan,
    PetSkillFamily.guard => PetTagColor.green,
    PetSkillFamily.defense => PetTagColor.blue,
    PetSkillFamily.revenge => PetTagColor.red,
  };
}

/// 技能 tag 颜色（对应 `.tag-gold / -cyan / -red / -blue / -green`）。
enum PetTagColor { gold, cyan, red, blue, green }

/// 珍兽技能。
@immutable
class PetSkill {
  const PetSkill({
    required this.name,
    required this.desc,
    required this.family,
    required this.base,
    required this.judge,
    required this.icon,
    required this.fx,
  });

  /// 技能名。
  final String name;

  /// 一句话说明（列表名下方，可空）。
  final String desc;

  /// 技能系（决定性格系数）。
  final PetSkillFamily family;

  /// 基础概率（%，即游戏内的「生效几率」）。
  final int base;

  /// 判定方式（如「受击判定」「攻击判定」）。
  final String judge;

  /// 技能图标资源名（如 `sk-fanji`，位于 assets/icons/）。
  final String icon;

  /// 详情长描述（弹窗 `sk-fx`）。
  final String fx;

  /// 是否有关键词（用于列表名下方展示描述）。
  bool get hasDesc => desc.isNotEmpty;

  /// 类型 tag 文案 —— 直接用技能系名，与筛选 chips 保持一致。
  String get tag => family.label;

  /// 类型 tag 颜色 —— 随技能系取色。
  PetTagColor get tagColor => family.tagColor;
}

/// 珍兽性格（含五系技能发动系数）。
@immutable
class PetChar {
  const PetChar({required this.key, required this.name, required this.factors});

  /// 性格 key（如 `danxiao` / `jingming`）。
  final String key;

  /// 性格名（胆小 / 谨慎 / 忠诚 / 精明 / 勇猛）。
  final String name;

  /// 五系发动系数（缺省按 1 处理）。
  final Map<PetSkillFamily, double> factors;

  /// 取某技能系的发动系数。
  double factorFor(PetSkillFamily family) => factors[family] ?? 1;
}

/// 系数文案：整数不带小数点（`1` / `2`），其余保留一位小数（`0.5` / `1.3`）。
String petFactorText(double factor) => factor == factor.roundToDouble()
    ? factor.toStringAsFixed(0)
    : factor.toStringAsFixed(1);

/// 技能库（基础概率取自概率表底部的「生效几率」列）。
///
/// 顺序与图片表格一致：报复（反击 · 吸血 · 反震）→ 防御（灵动 · 吸魔 ·
/// 打怒）→ 护主（忠心 · 灵气）；每个技能先普通版再高级版。
///
/// 归系说明：图片顶表只列了各系的代表技能，底部数据表另外给出「吸血」「吸魔」
/// 的基础概率 —— 「吸血」排在「反击 / 反震」之间，按报复系计（精明 ×2）；
/// 「吸魔」并入防御系（与「吸气」同系）。
const List<PetSkill> kPetSkills = [
  PetSkill(
    name: '反击',
    desc: '受击时一定几率反击',
    family: PetSkillFamily.revenge,
    base: 20,
    judge: '受击判定',
    icon: 'sk-fanji',
    fx: '受到攻击时按几率立刻回敬一击，伤害按自身外功计算。是肉盾型宝宝最经典的输出来源，体质越高越耐打，反击次数也越可观。',
  ),
  PetSkill(
    name: '高级反击',
    desc: '受击时反击 · 几率更高',
    family: PetSkillFamily.revenge,
    base: 30,
    judge: '受击判定',
    icon: 'sk-fanji',
    fx: '反击几率提升到 30%，挨打越多出手越勤。与「高级反震」一起佩戴后，近战目标往往进退两难。',
  ),
  PetSkill(
    name: '吸血',
    desc: '攻击命中后吸取气血',
    family: PetSkillFamily.revenge,
    base: 20,
    judge: '攻击判定',
    icon: 'sk-xixue',
    fx: '每次命中后按几率把所造成伤害的一部分转化为自身气血，续航能力明显提升，挂机刷怪几乎不用喂药。',
  ),
  PetSkill(
    name: '高级吸血',
    desc: '吸取气血 · 几率更高',
    family: PetSkillFamily.revenge,
    base: 30,
    judge: '攻击判定',
    icon: 'sk-xixue',
    fx: '吸血几率提升到 30%，配合高攻速技能可形成稳定的自愈循环，长时间拉锯战中收益成倍放大。',
  ),
  PetSkill(
    name: '反震',
    desc: '受击时反弹伤害',
    family: PetSkillFamily.revenge,
    base: 20,
    judge: '受击判定',
    icon: 'sk-fanzhen',
    fx: '受到近战攻击时按几率把部分伤害反弹给攻击者，对贴身输出的门派克制明显，越硬的宝宝收益越高。',
  ),
  PetSkill(
    name: '高级反震',
    desc: '反弹伤害 · 几率更高',
    family: PetSkillFamily.revenge,
    base: 30,
    judge: '受击判定',
    icon: 'sk-fanzhen',
    fx: '反震几率提升到 30%，反弹比例也更高，是硬抗物理输出的核心被动，配合「高级反击」形成反伤闭环。',
  ),
  PetSkill(
    name: '灵动',
    desc: '受击时提升闪避',
    family: PetSkillFamily.defense,
    base: 20,
    judge: '受击判定',
    icon: 'sk-lingdong',
    fx: '受击时按几率短暂提升自身闪避，更难被连续命中。适合需要站场吃伤害的宝宝，面对群怪时格外面子足。',
  ),
  PetSkill(
    name: '高级灵动',
    desc: '闪避加成 · 几率更高',
    family: PetSkillFamily.defense,
    base: 30,
    judge: '受击判定',
    icon: 'sk-lingdong',
    fx: '灵动几率提升到 30%，闪避加成的覆盖时间更长，在持续挨打的场合能把生存曲线整体抬高一档。',
  ),
  PetSkill(
    name: '吸魔',
    desc: '攻击命中后吸取法力',
    family: PetSkillFamily.defense,
    base: 20,
    judge: '攻击判定',
    icon: 'sk-ximo',
    fx: '命中后按几率吸取目标法力，对依赖技能循环的门派形成持续压制。与「打怒」同佩戴时，对手的技能节奏会被反复打断。',
  ),
  PetSkill(
    name: '高级吸魔',
    desc: '吸取法力 · 几率更高',
    family: PetSkillFamily.defense,
    base: 30,
    judge: '攻击判定',
    icon: 'sk-ximo',
    fx: '吸魔几率提升到 30%，吸取量更高。长时间消耗战里，对手往往还没打完一套就没蓝可用。',
  ),
  PetSkill(
    name: '打怒',
    desc: '攻击命中后清除怒气',
    family: PetSkillFamily.defense,
    base: 20,
    judge: '攻击判定',
    icon: 'sk-danu',
    fx: '命中时按几率清除目标部分怒气，直接打断对方的大招节奏。PVP 里对方起手攒怒时一记打怒，往往能瓦解整套连招。',
  ),
  PetSkill(
    name: '高级打怒',
    desc: '清除怒气 · 几率更高',
    family: PetSkillFamily.defense,
    base: 30,
    judge: '攻击判定',
    icon: 'sk-danu',
    fx: '打怒几率提升到 30%，更容易在对手攒满怒气之前把节奏压下去，是克制怒气爆发门派的关键被动。',
  ),
  PetSkill(
    name: '忠心',
    desc: '主人受击时替主人承伤',
    family: PetSkillFamily.guard,
    base: 7,
    judge: '受击判定',
    icon: 'sk-zhongxin',
    fx: '主人受到攻击时按几率挺身格挡，替主人承担部分伤害。「忠诚」性格触发率最高，是脆皮门派身边最可靠的一道盾。',
  ),
  PetSkill(
    name: '高级忠心',
    desc: '护主承伤 · 几率更高',
    family: PetSkillFamily.guard,
    base: 12,
    judge: '受击判定',
    icon: 'sk-zhongxin',
    fx: '忠心几率提升到 12%，且承伤比例更高，副本拉怪与 PVP 保命都靠它稳住局面，忠诚宝宝的核心被动。',
  ),
  PetSkill(
    name: '灵气',
    desc: '主人受击时回复气值',
    family: PetSkillFamily.guard,
    base: 15,
    judge: '受击判定',
    icon: 'sk-lingqi',
    fx: '主人受到攻击时按几率为主人回复气值，让主人的技能循环更顺畅。与「忠心」同佩时，既保命又保输出节奏。',
  ),
  PetSkill(
    name: '高级灵气',
    desc: '回复气值 · 几率更高',
    family: PetSkillFamily.guard,
    base: 25,
    judge: '受击判定',
    icon: 'sk-lingqi',
    fx: '灵气几率提升到 25%，回气量也更高，长时间作战里主人的续航与技能衔接都会稳定不少。',
  ),
];

/// 性格表：胆小 / 谨慎 / 忠诚 / 精明 / 勇猛（顺序与图片表格列一致）。
///
/// 系数逐格对应图片顶表；游戏内没有「通用」「内敛」这类性格，
/// 基础概率直接看技能自身的「生效几率」（详情弹窗里有）。
const List<PetChar> kPetChars = [
  PetChar(
    key: 'danxiao',
    name: '胆小',
    factors: {
      PetSkillFamily.physical: .5,
      PetSkillFamily.magic: 2,
      PetSkillFamily.guard: .5,
      PetSkillFamily.defense: 1,
      PetSkillFamily.revenge: .5,
    },
  ),
  PetChar(
    key: 'jinshen',
    name: '谨慎',
    factors: {
      PetSkillFamily.physical: .8,
      PetSkillFamily.magic: 1.3,
      PetSkillFamily.guard: 1.3,
      PetSkillFamily.defense: 2,
      PetSkillFamily.revenge: .8,
    },
  ),
  PetChar(
    key: 'zhongcheng',
    name: '忠诚',
    factors: {
      PetSkillFamily.physical: 1,
      PetSkillFamily.magic: 1,
      PetSkillFamily.guard: 2,
      PetSkillFamily.defense: 1,
      PetSkillFamily.revenge: 1,
    },
  ),
  PetChar(
    key: 'jingming',
    name: '精明',
    factors: {
      PetSkillFamily.physical: 1.3,
      PetSkillFamily.magic: .8,
      PetSkillFamily.guard: 1,
      PetSkillFamily.defense: .8,
      PetSkillFamily.revenge: 2,
    },
  ),
  PetChar(
    key: 'yongmeng',
    name: '勇猛',
    factors: {
      PetSkillFamily.physical: 2,
      PetSkillFamily.magic: .5,
      PetSkillFamily.guard: .8,
      PetSkillFamily.defense: .5,
      PetSkillFamily.revenge: 1.3,
    },
  ),
];

/// 技能发动概率：`min(100, round(基础概率 × 性格系数))`。
int petProbOf(PetSkill skill, PetChar ch) =>
    (skill.base * ch.factorFor(skill.family)).round().clamp(0, 100);

/// 概率条宽度（%）：`min(100, round(p × 3.3))`，让 30% 左右的技能条仍有辨识度。
int petProbBarWidth(int p) => (p * 3.3).round().clamp(0, 100);
