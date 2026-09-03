/// 兽魂查询 —— 领域模型与数据（与 UI 原型 `SOULS` 一致）。
///
/// 品质 → 字（金/紫/蓝/绿）；每只兽魂含 4 档成长效果（1-5 / 6-10 / 11-15 /
/// 16-20 级），卡片上方主/副词条取「末档（16-20 级）」数值。
library;

import 'package:flutter/foundation.dart';

/// 兽魂品质。
enum BeastSoulQuality {
  gold('金'),
  purple('紫'),
  blue('蓝'),
  green('绿');

  const BeastSoulQuality(this.label);

  /// 品质字（如「金」）。
  final String label;

  /// 原型 `q` 键。
  String get key => name;
}

/// 单档成长效果。
@immutable
class BeastSoulTier {
  const BeastSoulTier({
    required this.lv,
    required this.main,
    required this.subs,
    required this.fx,
  });

  /// 档位文案（如「1-5 级」）。
  final String lv;

  /// 主词条（如「火攻 +15」）。
  final String main;

  /// 副词条（1~2 条）。
  final List<String> subs;

  /// 特效描述（含 `<b>…</b>` 金强调标记，展示时解析）。
  final String fx;

  /// 分段按钮文案（去掉「 级」后缀，如 `1-5`）。
  String get segLabel => lv.replaceAll(' 级', '');

  /// 标题文案（如「1-5 级效果」）。
  String get title => '$lv效果';
}

/// 一只兽魂。
@immutable
class BeastSoul {
  const BeastSoul({
    required this.name,
    required this.quality,
    required this.icon,
    required this.score,
    required this.main,
    required this.subs,
    required this.tiers,
  });

  final String name;

  /// 品质。
  final BeastSoulQuality quality;

  /// 图标资源名（如 `flame`，位于 assets/icons/）。
  final String icon;

  /// 综合评分（0-100，进度条宽度直接取该百分比）。
  final int score;

  /// 主词条（末档，卡片展示）。
  final String main;

  /// 副词条（末档，卡片展示）。
  final List<String> subs;

  /// 4 档成长效果。
  final List<BeastSoulTier> tiers;
}

/// 兽魂库（对应原型 `SOULS`，卡片主/副词条取末档值）。
const List<BeastSoul> kBeastSouls = [
  BeastSoul(
    name: '赤炎兽魂',
    quality: BeastSoulQuality.gold,
    icon: 'flame',
    score: 96,
    main: '火攻 +42',
    subs: ['会心 +18', '命中 +21'],
    tiers: [
      BeastSoulTier(
        lv: '1-5 级',
        main: '火攻 +15',
        subs: ['会心 +7'],
        fx: '攻击有 3% 概率点燃目标',
      ),
      BeastSoulTier(
        lv: '6-10 级',
        main: '火攻 +22',
        subs: ['会心 +10', '命中 +12'],
        fx: '点燃概率提升至 5%',
      ),
      BeastSoulTier(
        lv: '11-15 级',
        main: '火攻 +32',
        subs: ['会心 +14', '命中 +16'],
        fx: '点燃附加 <b>2 秒灼烧</b>持续伤害',
      ),
      BeastSoulTier(
        lv: '16-20 级',
        main: '火攻 +42',
        subs: ['会心 +18', '命中 +21'],
        fx: '灼烧伤害提升 <b>50%</b>',
      ),
    ],
  ),
  BeastSoul(
    name: '玄冰兽魂',
    quality: BeastSoulQuality.gold,
    icon: 'gem',
    score: 92,
    main: '冰攻 +40',
    subs: ['会心防御 +15', '闪避 +19'],
    tiers: [
      BeastSoulTier(
        lv: '1-5 级',
        main: '冰攻 +14',
        subs: ['闪避 +7'],
        fx: '受击时 5% 概率冰冻减速攻击者',
      ),
      BeastSoulTier(
        lv: '6-10 级',
        main: '冰攻 +21',
        subs: ['会心防御 +10', '闪避 +11'],
        fx: '冰冻概率提升至 8%',
      ),
      BeastSoulTier(
        lv: '11-15 级',
        main: '冰攻 +30',
        subs: ['会心防御 +13', '闪避 +15'],
        fx: '冰冻持续 <b>2 秒</b>',
      ),
      BeastSoulTier(
        lv: '16-20 级',
        main: '冰攻 +40',
        subs: ['会心防御 +15', '闪避 +19'],
        fx: '冰冻目标受到的伤害 <b>+10%</b>',
      ),
    ],
  ),
  BeastSoul(
    name: '紫电兽魂',
    quality: BeastSoulQuality.purple,
    icon: 'spark',
    score: 86,
    main: '玄攻 +35',
    subs: ['身法 +12', '命中 +9'],
    tiers: [
      BeastSoulTier(
        lv: '1-5 级',
        main: '玄攻 +12',
        subs: ['身法 +4'],
        fx: '攻击有 4% 概率附带感电',
      ),
      BeastSoulTier(
        lv: '6-10 级',
        main: '玄攻 +19',
        subs: ['身法 +7', '命中 +5'],
        fx: '感电概率提升至 6%',
      ),
      BeastSoulTier(
        lv: '11-15 级',
        main: '玄攻 +27',
        subs: ['身法 +10', '命中 +7'],
        fx: '感电目标受会心伤害 <b>+8%</b>',
      ),
      BeastSoulTier(
        lv: '16-20 级',
        main: '玄攻 +35',
        subs: ['身法 +12', '命中 +9'],
        fx: '感电可叠加 <b>2 层</b>',
      ),
    ],
  ),
  BeastSoul(
    name: '幽冥兽魂',
    quality: BeastSoulQuality.purple,
    icon: 'flame',
    score: 84,
    main: '毒攻 +34',
    subs: ['会心 +14', '定力 +8'],
    tiers: [
      BeastSoulTier(
        lv: '1-5 级',
        main: '毒攻 +12',
        subs: ['会心 +5'],
        fx: '攻击有 5% 概率使目标中毒',
      ),
      BeastSoulTier(
        lv: '6-10 级',
        main: '毒攻 +18',
        subs: ['会心 +8', '定力 +4'],
        fx: '中毒概率提升至 8%',
      ),
      BeastSoulTier(
        lv: '11-15 级',
        main: '毒攻 +26',
        subs: ['会心 +11', '定力 +6'],
        fx: '中毒改为<b>每秒掉血</b>',
      ),
      BeastSoulTier(
        lv: '16-20 级',
        main: '毒攻 +34',
        subs: ['会心 +14', '定力 +8'],
        fx: '中毒目标受到的<b>治疗 -20%</b>',
      ),
    ],
  ),
  BeastSoul(
    name: '磐石兽魂',
    quality: BeastSoulQuality.blue,
    icon: 'shield',
    score: 76,
    main: '体力 +30',
    subs: ['防御 +150'],
    tiers: [
      BeastSoulTier(
        lv: '1-5 级',
        main: '体力 +10',
        subs: ['防御 +50'],
        fx: '受到暴击伤害 -3%',
      ),
      BeastSoulTier(
        lv: '6-10 级',
        main: '体力 +16',
        subs: ['防御 +85'],
        fx: '受到暴击伤害 -5%',
      ),
      BeastSoulTier(
        lv: '11-15 级',
        main: '体力 +23',
        subs: ['防御 +118'],
        fx: '受击后回复 <b>2%</b> 气血',
      ),
      BeastSoulTier(
        lv: '16-20 级',
        main: '体力 +30',
        subs: ['防御 +150'],
        fx: '气血低于 30% 时防御 <b>+15%</b>',
      ),
    ],
  ),
  BeastSoul(
    name: '疾风兽魂',
    quality: BeastSoulQuality.green,
    icon: 'pct',
    score: 68,
    main: '身法 +22',
    subs: ['闪避 +14'],
    tiers: [
      BeastSoulTier(
        lv: '1-5 级',
        main: '身法 +8',
        subs: ['闪避 +5'],
        fx: '移动速度 +3%',
      ),
      BeastSoulTier(
        lv: '6-10 级',
        main: '身法 +12',
        subs: ['闪避 +8'],
        fx: '闪避成功后下次攻击必中',
      ),
      BeastSoulTier(
        lv: '11-15 级',
        main: '身法 +17',
        subs: ['闪避 +11'],
        fx: '移动速度提升至 <b>4%</b>',
      ),
      BeastSoulTier(
        lv: '16-20 级',
        main: '身法 +22',
        subs: ['闪避 +14'],
        fx: '移动速度 <b>+5%</b>，闪避 <b>+2%</b>',
      ),
    ],
  ),
];
