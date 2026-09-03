/// 宝宝技能释放概率 —— 领域模型与公式（与 UI 原型一致）。
///
/// 概率 = 实测基准值 × 性格修正系数（上限 100%），实际还受悟性与技能等级影响。
/// 数据来源与原型 `PROB_SKILLS` / `PET_CHARS` 一致。
library;

import 'package:flutter/foundation.dart';

/// 技能分类。
enum PetSkillCat { atk, st, sup }

extension PetSkillCatX on PetSkillCat {
  /// 分类展示名（如「攻击类」）。
  String get label => switch (this) {
        PetSkillCat.atk => '攻击类',
        PetSkillCat.st => '状态类',
        PetSkillCat.sup => '辅助类',
      };

  /// 原型 `cat` 字段。
  String get key => switch (this) {
        PetSkillCat.atk => 'atk',
        PetSkillCat.st => 'st',
        PetSkillCat.sup => 'sup',
      };
}

/// 技能 tag 颜色（对应原型 `tc` 字段 → `.tag-gold / -cyan / -red / -blue / -green`）。
enum PetTagColor { gold, cyan, red, blue, green }

/// 宝宝技能。
@immutable
class PetSkill {
  const PetSkill({
    required this.name,
    required this.desc,
    required this.cat,
    required this.tag,
    required this.tagColor,
    required this.base,
    required this.judge,
  });

  /// 技能名。
  final String name;

  /// 描述（可空，如「冰属性附加伤害」）。
  final String desc;

  /// 分类。
  final PetSkillCat cat;

  /// 类型 tag 文案（如「自动攻击」「冰系」）。
  final String tag;

  /// tag 颜色。
  final PetTagColor tagColor;

  /// 实测基准值（%）。
  final int base;

  /// 判定方式（如「攻击判定」「周期判定」「受击判定」）。
  final String judge;

  /// 是否有关键词（用于列表名下方展示描述）。
  bool get hasDesc => desc.isNotEmpty;
}

/// 宝宝性格（含三类技能触发系数）。
@immutable
class PetChar {
  const PetChar({
    required this.key,
    required this.name,
    required this.atk,
    required this.st,
    required this.sup,
  });

  /// 原型 `k` 字段（如 `general`）。
  final String key;

  /// 性格名（如「通用」「勇猛」）。
  final String name;

  /// 攻击类系数。
  final double atk;

  /// 状态类系数。
  final double st;

  /// 辅助类系数。
  final double sup;

  /// 取某分类的修正系数。
  double factorFor(PetSkillCat cat) => switch (cat) {
        PetSkillCat.atk => atk,
        PetSkillCat.st => st,
        PetSkillCat.sup => sup,
      };
}

/// 技能库（对应原型 `PROB_SKILLS`）。
const List<PetSkill> kPetSkills = [
  PetSkill(name: '猛击', desc: '', cat: PetSkillCat.atk, tag: '自动攻击', tagColor: PetTagColor.gold, base: 20, judge: '攻击判定'),
  PetSkill(name: '连击', desc: '', cat: PetSkillCat.atk, tag: '自动攻击', tagColor: PetTagColor.gold, base: 15, judge: '攻击判定'),
  PetSkill(name: '痛击', desc: '', cat: PetSkillCat.atk, tag: '自动攻击', tagColor: PetTagColor.gold, base: 12, judge: '攻击判定'),
  PetSkill(name: '寒冰咒', desc: '冰属性附加伤害', cat: PetSkillCat.atk, tag: '冰系', tagColor: PetTagColor.cyan, base: 10, judge: '攻击判定'),
  PetSkill(name: '烈火咒', desc: '火属性附加伤害', cat: PetSkillCat.atk, tag: '火系', tagColor: PetTagColor.red, base: 10, judge: '攻击判定'),
  PetSkill(name: '虚弱', desc: '降低目标攻击力', cat: PetSkillCat.st, tag: '状态', tagColor: PetTagColor.blue, base: 8, judge: '周期判定'),
  PetSkill(name: '打怒', desc: '清除目标怒气', cat: PetSkillCat.st, tag: '状态', tagColor: PetTagColor.blue, base: 8, judge: '周期判定'),
  PetSkill(name: '迟缓', desc: '降低目标移动速度', cat: PetSkillCat.st, tag: '状态', tagColor: PetTagColor.blue, base: 6, judge: '周期判定'),
  PetSkill(name: '吸血', desc: '伤害转化气血', cat: PetSkillCat.sup, tag: '辅助', tagColor: PetTagColor.green, base: 6, judge: '攻击判定'),
  PetSkill(name: '护主', desc: '主人受击时触发', cat: PetSkillCat.sup, tag: '辅助', tagColor: PetTagColor.green, base: 100, judge: '受击判定'),
];

/// 性格表（对应原型 `PET_CHARS`）。
const List<PetChar> kPetChars = [
  PetChar(key: 'general', name: '通用', atk: 1, st: 1, sup: 1),
  PetChar(key: 'yongmeng', name: '勇猛', atk: 1.3, st: .8, sup: .9),
  PetChar(key: 'danxiao', name: '胆小', atk: 1.15, st: 1, sup: .95),
  PetChar(key: 'jinshen', name: '谨慎', atk: .85, st: 1.1, sup: 1.3),
  PetChar(key: 'jingming', name: '精明', atk: .9, st: 1.4, sup: 1),
  PetChar(key: 'zhongcheng', name: '忠诚', atk: .85, st: .95, sup: 1.5),
  PetChar(key: 'neilian', name: '内敛', atk: 1.2, st: 1.05, sup: .9),
];

/// 技能释放概率：`min(100, round(基准值 × 性格系数))`。
/// 对应原型 `probOf = (sk,ch)=>Math.min(100,Math.round(sk.base*ch.f[sk.cat]))`。
int petProbOf(PetSkill skill, PetChar ch) =>
    (skill.base * ch.factorFor(skill.cat)).round().clamp(0, 100);

/// 概率条宽度（%）：`min(100, round(p × 3.3))`。
/// 对应原型 `w = Math.min(100,Math.round(p*3.3))`。
int petProbBarWidth(int p) => (p * 3.3).round().clamp(0, 100);
