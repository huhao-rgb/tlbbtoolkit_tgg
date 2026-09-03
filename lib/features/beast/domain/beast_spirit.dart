/// 兽灵图鉴 —— 领域模型与数据（与 UI 原型 `SPIRITS` 一致）。
///
/// 9 只兽灵：白泽/穷奇/饕餮/梼杌/九尾/貔貅/睚眦/狻猊/年兽；每只有
/// 稀有度(传说/史诗/稀有/普通)、流派(内功/外功/平衡)、星级、携带等级、
/// 头像字徽与 4 档成长(1-5 / 6-10 / 11-15 / 16-20 级)。
library;

import 'package:flutter/foundation.dart';

/// 稀有度配色键（对应原型 `rt`：blue / red / gold / ''=普通）。
enum BeastRarityTone {
  normal(''),
  gold('gold'),
  blue('blue'),
  red('red');

  const BeastRarityTone(this.key);

  final String key;
}

/// 属性流派。
enum BeastAttr {
  nei('内功'),
  wai('外功'),
  bal('平衡');

  const BeastAttr(this.label);

  final String label;
}

/// 单档成长效果。
@immutable
class BeastSpiritTier {
  const BeastSpiritTier({
    required this.lv,
    required this.main,
    required this.subs,
    required this.fx,
  });

  /// 档位（如 `1-5`）。
  final String lv;

  /// 成长 · 主。
  final String main;

  /// 成长 · 副（1~2 条）。
  final List<String> subs;

  /// 特效（含 `<b>…</b>` 强调标记）。
  final String fx;

  /// 标题文案（如 `1-5 级效果`）。
  String get title => '$lv 级效果';
}

/// 一只兽灵。
@immutable
class BeastSpirit {
  const BeastSpirit({
    required this.name,
    required this.rarity,
    required this.tone,
    required this.stars,
    required this.attr,
    required this.role,
    required this.level,
    required this.avatar,
    required this.tiers,
  });

  final String name;

  /// 稀有度文案（传说 / 史诗 / 稀有 / 普通）。
  final String rarity;

  /// 配色键。
  final BeastRarityTone tone;

  /// 星级（1~5）。
  final int stars;

  /// 属性流派。
  final BeastAttr attr;

  /// 定位。
  final String role;

  /// 携带等级。
  final int level;

  /// 头像字徽。
  final String avatar;

  /// 4 档成长。
  final List<BeastSpiritTier> tiers;

  /// 是否普通（无配色）。
  bool get isCommon => tone == BeastRarityTone.normal;
}

/// 兽灵库（对应原型 `SPIRITS`）。
const List<BeastSpirit> kBeastSpirits = [
  BeastSpirit(
    name: '白泽',
    rarity: '传说',
    tone: BeastRarityTone.blue,
    stars: 5,
    attr: BeastAttr.nei,
    role: '群攻·治疗',
    level: 85,
    avatar: '白',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '内功攻击 +40',
        subs: ['气上限 +300'],
        fx: '治疗量 <b>+5%</b>',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '内功攻击 +65',
        subs: ['治疗强度 +50'],
        fx: '群攻技能<b>目标数 +1</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '内功攻击 +95',
        subs: ['治疗强度 +75'],
        fx: '治疗附加 <b>3 秒持续回复</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '内功攻击 +130',
        subs: ['治疗强度 +105'],
        fx: '治疗时<b>解除 1 个负面状态</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '穷奇',
    rarity: '传说',
    tone: BeastRarityTone.red,
    stars: 5,
    attr: BeastAttr.wai,
    role: '单体爆发',
    level: 85,
    avatar: '穷',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '外功攻击 +45',
        subs: ['会心 +15'],
        fx: '暴击伤害 <b>+8%</b>',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '外功攻击 +72',
        subs: ['会心 +24'],
        fx: '爆发技能<b>无视 10% 防御</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '外功攻击 +105',
        subs: ['会心 +35'],
        fx: '暴击后下次攻击伤害 <b>+15%</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '外功攻击 +145',
        subs: ['会心 +48'],
        fx: '击杀目标<b>刷新爆发技能</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '饕餮',
    rarity: '史诗',
    tone: BeastRarityTone.gold,
    stars: 4,
    attr: BeastAttr.bal,
    role: '持续吸收',
    level: 75,
    avatar: '饕',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '吸收护盾 +400',
        subs: ['攻击回复 2% 伤害'],
        fx: '—',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '吸收护盾 +650',
        subs: ['吸血 5%'],
        fx: '护盾存在时<b>防御 +8%</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '吸收护盾 +950',
        subs: ['全属性 +20'],
        fx: '护盾破碎时<b>对周围爆炸</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '吸收护盾 +1300',
        subs: ['全属性 +30'],
        fx: '吸收量转化为<b>战斗内永久增益</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '梼杌',
    rarity: '史诗',
    tone: BeastRarityTone.red,
    stars: 4,
    attr: BeastAttr.wai,
    role: '破防压制',
    level: 75,
    avatar: '梼',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '外功攻击 +38',
        subs: ['破防 +40'],
        fx: '攻击<b>无视 5% 防御</b>',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '外功攻击 +60',
        subs: ['破防 +65'],
        fx: '附加<b>破防标记</b>：受创 +6%',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '外功攻击 +88',
        subs: ['破防 +95'],
        fx: '标记<b>可叠加 2 层</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '外功攻击 +120',
        subs: ['破防 +130'],
        fx: '压制：目标防御 <b>-15%</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '九尾',
    rarity: '史诗',
    tone: BeastRarityTone.blue,
    stars: 4,
    attr: BeastAttr.nei,
    role: '魅惑控制',
    level: 65,
    avatar: '九',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '内功攻击 +36',
        subs: ['命中 +25'],
        fx: '技能 <b>4% 概率魅惑</b> 1 秒',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '内功攻击 +58',
        subs: ['命中 +40'],
        fx: '魅惑概率提升至 <b>6%</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '内功攻击 +85',
        subs: ['命中 +58'],
        fx: '魅惑期间目标<b>受伤 +12%</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '内功攻击 +118',
        subs: ['命中 +78'],
        fx: '魅惑结束<b>返还 30% 冷却</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '貔貅',
    rarity: '稀有',
    tone: BeastRarityTone.gold,
    stars: 3,
    attr: BeastAttr.bal,
    role: '聚财增益',
    level: 55,
    avatar: '貔',
    tiers: [
      BeastSpiritTier(lv: '1-5', main: '全属性 +12', subs: ['银两掉落 +5%'], fx: '—'),
      BeastSpiritTier(
        lv: '6-10',
        main: '全属性 +20',
        subs: ['银两掉落 +8%'],
        fx: '自身增益效果 <b>+8%</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '全属性 +30',
        subs: ['气上限 +500'],
        fx: '银两掉落提升至 <b>+10%</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '全属性 +42',
        subs: ['气上限 +800'],
        fx: '战斗胜利<b>额外宝箱 5% 概率</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '睚眦',
    rarity: '稀有',
    tone: BeastRarityTone.red,
    stars: 3,
    attr: BeastAttr.wai,
    role: '嗜血连击',
    level: 45,
    avatar: '睚',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '外功攻击 +35',
        subs: ['吸血 3%'],
        fx: '连击概率 <b>+4%</b>',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '外功攻击 +55',
        subs: ['吸血 5%'],
        fx: '连击概率提升至 <b>+6%</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '外功攻击 +80',
        subs: ['吸血 7%'],
        fx: '嗜血：气血越低攻击越高（<b>至多 +12%</b>）',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '外功攻击 +110',
        subs: ['吸血 9%'],
        fx: '连击触发时<b>回复 3% 气血</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '狻猊',
    rarity: '稀有',
    tone: BeastRarityTone.blue,
    stars: 3,
    attr: BeastAttr.nei,
    role: '火焰吐息',
    level: 35,
    avatar: '狻',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '内功攻击 +34',
        subs: ['火攻 +15'],
        fx: '吐息范围 <b>+10%</b>',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '内功攻击 +54',
        subs: ['火攻 +24'],
        fx: '附加<b>3 秒灼烧</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '内功攻击 +78',
        subs: ['火攻 +35'],
        fx: '灼烧<b>传播</b>至邻近目标',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '内功攻击 +108',
        subs: ['火攻 +48'],
        fx: '灼烧目标受伤 <b>+15%</b>',
      ),
    ],
  ),
  BeastSpirit(
    name: '年兽',
    rarity: '普通',
    tone: BeastRarityTone.normal,
    stars: 2,
    attr: BeastAttr.bal,
    role: '新春限定',
    level: 25,
    avatar: '年',
    tiers: [
      BeastSpiritTier(
        lv: '1-5',
        main: '全属性 +15',
        subs: ['气上限 +200'],
        fx: '爆竹：<b>4% 概率眩晕</b> 1 秒',
      ),
      BeastSpiritTier(
        lv: '6-10',
        main: '全属性 +25',
        subs: ['气上限 +350'],
        fx: '眩晕概率提升至 <b>6%</b>',
      ),
      BeastSpiritTier(
        lv: '11-15',
        main: '全属性 +36',
        subs: ['气上限 +500'],
        fx: '新春祝福：队伍经验 <b>+10%</b>',
      ),
      BeastSpiritTier(
        lv: '16-20',
        main: '全属性 +50',
        subs: ['气上限 +700'],
        fx: '变身形态 <b>8 秒</b>，全属性翻倍',
      ),
    ],
  ),
];
