/// 兽魂查询 —— 领域模型与数据（与 UI 原型 `SOULS_OFF` 一致）。
///
/// 十五大兽魂按类型分三类（神兽魂 / 荒兽魂 / 灵兽魂），每只含：
/// - 出战技能（`cs`）：主动/被动 + 完整描述；
/// - 融魂技能（`rh`）：魂境阶级 1–6 阶数值（官网目前仅公布 6 阶满阶）。
///
/// 数据源：官网资料站「兽魂技能」、官网攻略站「融魂、技能和扩展属性」。
library;

import 'package:flutter/foundation.dart';

/// 兽魂类型（对应原型 `SOUL_TAG`：shen / huang / ling）。
enum BeastSoulType {
  shen('神兽魂'),
  huang('荒兽魂'),
  ling('灵兽魂');

  const BeastSoulType(this.label);

  /// 类型名（如「神兽魂」）。
  final String label;
}

/// 出战技能（原型 `cs`）。
@immutable
class BeastSoulSkill {
  const BeastSoulSkill({
    required this.name,
    required this.description,
    this.iconPath,
  });

  /// 技能名（如「逆鳞」）。
  final String name;

  /// 完整描述，带「主动：/被动：」前缀。
  final String description;

  /// 技能图标资源路径（`assets/beast_soul/*.webp`）；官网未提供时为 null。
  final String? iconPath;

  /// 是否被动技能（原型按 `d.startsWith('被动')` 判定）。
  bool get isPassive => description.startsWith('被动');

  /// 主动 / 被动。
  String get kind => isPassive ? '被动' : '主动';

  /// 去掉「主动：/被动：」前缀后的描述正文。
  String get body => description.replaceFirst(RegExp(r'^主动：|^被动：'), '');
}

/// 融魂技能一档（魂境阶级 1–6 阶）。
@immutable
class BeastSoulRhTier {
  const BeastSoulRhTier({required this.lv, this.description});

  /// 魂境阶级（1–6）。
  final int lv;

  /// 该阶融魂数值；官网未公布时为 null。
  final String? description;

  /// 分段按钮文案（如 `6 阶`）。
  String get segLabel => '$lv 阶';
}

/// 融魂技能（原型 `rh`）。
@immutable
class BeastSoulRh {
  const BeastSoulRh({
    required this.name,
    required this.tiers,
    this.iconPath,
  });

  /// 融魂技能名（如「青龙魂附·天罡」）。
  final String name;

  /// 1–6 阶数值。
  final List<BeastSoulRhTier> tiers;

  /// 融魂技能图标资源路径；官网未提供时为 null。
  final String? iconPath;
}

/// 一只兽魂。
@immutable
class BeastSoul {
  const BeastSoul({
    required this.name,
    required this.type,
    required this.cs,
    required this.rh,
  });

  final String name;

  /// 类型（决定卡片 / 弹窗配色）。
  final BeastSoulType type;

  /// 出战技能。
  final BeastSoulSkill cs;

  /// 融魂技能。
  final BeastSoulRh rh;
}

/// 兽魂库（对应原型 `SOULS_OFF`，十五大兽魂）。
const List<BeastSoul> kBeastSouls = [
  // ---- 神兽魂 ----
  BeastSoul(
    name: '青龙',
    type: BeastSoulType.shen,
    cs: BeastSoulSkill(
      name: '逆鳞',
      description: '主动：减少主人当前受到的封穴、麻痹、散功、封印、失明技能效果3秒时间，冷却300秒。',
      iconPath: 'assets/beast_soul/soul_0_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '青龙魂附·天罡',
      iconPath: 'assets/beast_soul/soul_0_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的冰攻击350点 2）提高主人的忽略目标冰抗125点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '白虎',
    type: BeastSoulType.shen,
    cs: BeastSoulSkill(
      name: '慑天',
      description: '被动：继承主人20%的内外功攻击、35%的命中和10%的血上限。',
      iconPath: 'assets/beast_soul/soul_1_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '白虎魂附·永夜',
      iconPath: 'assets/beast_soul/soul_1_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的玄攻击350点 2）提高主人的忽略目标玄抗125点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '玄武',
    type: BeastSoulType.shen,
    cs: BeastSoulSkill(
      name: '镇伏',
      description: '主动：给周围10米范围内的10个敌对目标上状态，使其对珍兽造成的伤害降低70%，持续10秒，冷却120秒。',
      iconPath: 'assets/beast_soul/soul_2_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '玄武魂附·九幽',
      iconPath: 'assets/beast_soul/soul_2_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的毒攻击350点 2）提高主人的忽略目标毒抗125点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '朱雀',
    type: BeastSoulType.shen,
    cs: BeastSoulSkill(
      name: '涅槃',
      description: '被动：死亡后立即复活，且复活后，重置冷却时间在2分钟内的珍兽技能冷却，同时；力量、灵气、体力、定力、身法各增加100点，持续30秒，冷却时间200秒。',
      iconPath: 'assets/beast_soul/soul_3_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '朱雀魂附·重明',
      iconPath: 'assets/beast_soul/soul_3_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的火攻击350点 2）提高主人的忽略目标火抗125点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '九尾',
    type: BeastSoulType.shen,
    cs: BeastSoulSkill(
      name: '千幻',
      description: '主动：对周围10米范围内的敌对珍兽造成一次普攻伤害，并按照对方珍兽兽魂等级给予散功，神兽6秒、荒兽8秒、灵兽10秒、无兽魂12秒，冷却时间120秒。',
      iconPath: 'assets/beast_soul/soul_4_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '九尾魂附·千秋',
      iconPath: 'assets/beast_soul/soul_4_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的血上限21000点 2）提高主人对珍兽造成的伤害45%',
        ),
      ],
    ),
  ),
  // ---- 荒兽魂 ----
  BeastSoul(
    name: '锦鳞',
    type: BeastSoulType.huang,
    cs: BeastSoulSkill(
      name: '溯洄',
      description: '被动：死亡时，给主人一个状态，可使主人在任何状态下，不用读条立即召唤珍兽，且使珍兽无敌2秒，状态持续15秒，冷却时间200秒。',
      iconPath: 'assets/beast_soul/soul_5_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '锦鳞魂附·寒潮',
      iconPath: 'assets/beast_soul/soul_5_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的冰攻击245点 2）提高主人的命中2740点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '幻蝶',
    type: BeastSoulType.huang,
    cs: BeastSoulSkill(
      name: '萦舞',
      description: '主动：牺牲自己，使主人进入无敌、围困状态，持续15秒，冷却300秒。（注：使用技能后会生成对应BUFF，此BUFF可手动取消）',
    ),
    rh: BeastSoulRh(
      name: '幻蝶魂附·晓梦',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的玄攻击245点 2）提高主人的命中2740点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '鹿蜀',
    type: BeastSoulType.huang,
    cs: BeastSoulSkill(
      name: '灵犀',
      description: '主动：增加主人10%命中率，减少主人10%闪避率，持续15秒，冷却120秒。',
      iconPath: 'assets/beast_soul/soul_7_cs.webp',
    ),
    rh: BeastSoulRh(
      name: '鹿蜀魂附·聆风',
      iconPath: 'assets/beast_soul/soul_7_rh.webp',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的会心40点 2）提高主人的会心防御40点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '霜鹤',
    type: BeastSoulType.huang,
    cs: BeastSoulSkill(
      name: '寻影',
      description: '主动：标记目标，使目标无法隐身，无法回城。切换场景消失，持续40秒，冷却120秒。',
    ),
    rh: BeastSoulRh(
      name: '霜鹤魂附·鸩羽',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的毒攻击245点 2）提高主人的命中2740点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '金乌',
    type: BeastSoulType.huang,
    cs: BeastSoulSkill(
      name: '夕照',
      description: '被动：珍兽受到致命一击时，免疫此次伤害，并获得有40000生命值的护盾，护盾承受100%的伤害，同时不受控制，持续10秒，冷却时间200秒。',
    ),
    rh: BeastSoulRh(
      name: '金乌魂附·燎日',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的火攻击245点 2）提高主人的命中2740点',
        ),
      ],
    ),
  ),
  // ---- 灵兽魂 ----
  BeastSoul(
    name: '赤熊',
    type: BeastSoulType.ling,
    cs: BeastSoulSkill(
      name: '撼岳',
      description: '主动：对自身6米范围内最多10个目标造成一次200%的伤害，冷却时间120秒。',
    ),
    rh: BeastSoulRh(
      name: '赤熊魂附·摧山',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的外功攻击4000点 2）提高主人的内功攻击4000点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '白驹',
    type: BeastSoulType.ling,
    cs: BeastSoulSkill(
      name: '逐风',
      description: '主动：提高主人移动速度40%，持续10秒，冷却时间200秒。',
    ),
    rh: BeastSoulRh(
      name: '白驹魂附·守心',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的外功防御4000点 2）提高主人的内功防御4000点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '灵蝉',
    type: BeastSoulType.ling,
    cs: BeastSoulSkill(
      name: '悲秋',
      description: '主动：只能对敌对珍兽使用，使自身和目标无法移动，无法攻击，无法使用技能，持续15秒，冷却120秒。',
    ),
    rh: BeastSoulRh(
      name: '灵蝉魂附·碎影',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的命中2329点 2）提高主人的闪避893点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '苍狼',
    type: BeastSoulType.ling,
    cs: BeastSoulSkill(
      name: '煞月',
      description: '被动：自身血量低于50%时，造成的伤害提高50%。',
    ),
    rh: BeastSoulRh(
      name: '苍狼魂附·噬月',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的血上限9371点 2）提高主人的会心24点',
        ),
      ],
    ),
  ),
  BeastSoul(
    name: '飞羚',
    type: BeastSoulType.ling,
    cs: BeastSoulSkill(
      name: '星驰',
      description: '被动：主人受到的减速效果，时间减免55%。',
    ),
    rh: BeastSoulRh(
      name: '飞羚魂附·灵眷',
      tiers: [
        BeastSoulRhTier(lv: 1),
        BeastSoulRhTier(lv: 2),
        BeastSoulRhTier(lv: 3),
        BeastSoulRhTier(lv: 4),
        BeastSoulRhTier(lv: 5),
        BeastSoulRhTier(
          lv: 6,
          description: '1）提高主人的体力142点 2）提高主人的会心防御24点',
        ),
      ],
    ),
  ),
];
