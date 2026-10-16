/// 兽灵技能效果 —— 领域模型与数据（与 UI 原型 `v-beast-skill` 一致）。
///
/// 5 个兽灵技能：破军/天罚（主动）、嗜血/护主（被动）、威慑（控制）；
/// 每个技能含一句简述与 Lv.1-5 等级数值行（Lv / 效果 / 冷却·触发）。
library;

import 'package:flutter/foundation.dart';

/// 技能类别（决定 tag 配色：主动=金 / 被动=紫 / 控制=蓝）。
enum BeastSkillKind {
  active('主动'),
  passive('被动'),
  control('控制');

  const BeastSkillKind(this.label);

  final String label;
}

/// 单条等级数值行（`.lv-row`）。
@immutable
class BeastSkillRow {
  const BeastSkillRow({
    required this.lv,
    required this.effect,
    required this.note,
  });

  /// 等级标签（如 `Lv.1`）。
  final String lv;

  /// 效果（如 `造成 180% 伤害`）。
  final String effect;

  /// 冷却 / 触发（如 `冷却 40s`、`常驻生效`）。
  final String note;
}

/// 一个兽灵技能。
@immutable
class BeastSkill {
  const BeastSkill({
    required this.name,
    required this.kind,
    required this.brief,
    required this.rows,
  });

  final String name;
  final BeastSkillKind kind;

  /// 一句话简述（`.acc-brief`）。
  final String brief;

  /// Lv.1-5 等级数值行。
  final List<BeastSkillRow> rows;
}

/// 兽灵技能库（对应原型 `v-beast-skill` 内 5 个手风琴）。
const List<BeastSkill> kBeastSkills = [
  BeastSkill(
    name: '破军',
    kind: BeastSkillKind.active,
    brief: '挥出凌厉一击，对目标造成高额比例伤害',
    rows: [
      BeastSkillRow(lv: 'Lv.1', effect: '造成 180% 伤害', note: '冷却 40s'),
      BeastSkillRow(lv: 'Lv.2', effect: '造成 200% 伤害', note: '冷却 40s'),
      BeastSkillRow(lv: 'Lv.3', effect: '造成 220% 伤害', note: '冷却 38s'),
      BeastSkillRow(lv: 'Lv.4', effect: '造成 240% 伤害', note: '冷却 36s'),
      BeastSkillRow(lv: 'Lv.5', effect: '造成 260% 伤害', note: '冷却 34s'),
    ],
  ),
  BeastSkill(
    name: '天罚',
    kind: BeastSkillKind.active,
    brief: '引落天雷，对范围内敌人造成伤害并短暂减速',
    rows: [
      BeastSkillRow(lv: 'Lv.1', effect: '140% 范围伤害', note: '冷却 50s'),
      BeastSkillRow(lv: 'Lv.2', effect: '160% 范围伤害', note: '冷却 48s'),
      BeastSkillRow(lv: 'Lv.3', effect: '180% 范围伤害', note: '冷却 46s'),
      BeastSkillRow(lv: 'Lv.4', effect: '200% 范围伤害', note: '冷却 44s'),
      BeastSkillRow(lv: 'Lv.5', effect: '220% 范围伤害 + 减速 30%', note: '冷却 42s'),
    ],
  ),
  BeastSkill(
    name: '嗜血',
    kind: BeastSkillKind.passive,
    brief: '攻击命中后将部分伤害转化为自身气血',
    rows: [
      BeastSkillRow(lv: 'Lv.1', effect: '吸血 8%', note: '常驻生效'),
      BeastSkillRow(lv: 'Lv.2', effect: '吸血 10%', note: '常驻生效'),
      BeastSkillRow(lv: 'Lv.3', effect: '吸血 12%', note: '常驻生效'),
      BeastSkillRow(lv: 'Lv.4', effect: '吸血 14%', note: '常驻生效'),
      BeastSkillRow(lv: 'Lv.5', effect: '吸血 16%', note: '常驻生效'),
    ],
  ),
  BeastSkill(
    name: '护主',
    kind: BeastSkillKind.passive,
    brief: '主人受到攻击时，为其分摊部分伤害',
    rows: [
      BeastSkillRow(lv: 'Lv.1', effect: '主人减伤 4%', note: '触发间隔 8s'),
      BeastSkillRow(lv: 'Lv.2', effect: '主人减伤 6%', note: '触发间隔 8s'),
      BeastSkillRow(lv: 'Lv.3', effect: '主人减伤 8%', note: '触发间隔 7s'),
      BeastSkillRow(lv: 'Lv.4', effect: '主人减伤 10%', note: '触发间隔 7s'),
      BeastSkillRow(lv: 'Lv.5', effect: '主人减伤 12%', note: '触发间隔 6s'),
    ],
  ),
  BeastSkill(
    name: '威慑',
    kind: BeastSkillKind.control,
    brief: '低吼震慑目标，命中后大幅降低其移动速度',
    rows: [
      BeastSkillRow(lv: 'Lv.1', effect: '减速 30%，持续 3s', note: '冷却 25s'),
      BeastSkillRow(lv: 'Lv.2', effect: '减速 35%，持续 3s', note: '冷却 25s'),
      BeastSkillRow(lv: 'Lv.3', effect: '减速 40%，持续 4s', note: '冷却 24s'),
      BeastSkillRow(lv: 'Lv.4', effect: '减速 45%，持续 4s', note: '冷却 23s'),
      BeastSkillRow(lv: 'Lv.5', effect: '减速 50%，持续 5s', note: '冷却 22s'),
    ],
  ),
];
