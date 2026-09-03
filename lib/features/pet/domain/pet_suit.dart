/// 宝宝套装图鉴 —— 领域模型与数据（与 UI 原型 `v-pet-suit` 一致）。
///
/// 六大性格套装 × 三档（75 / 85 / 95），每套：
/// - 分类 / 图标 / 适配类型；
/// - 2 件 / 3 件效果随档位变化；
/// - 五件套部件（头饰 / 铠甲 / 项圈 / 利爪 / 玉佩）的主副词条随档位变化。
/// 另含套装兑换 / 升星材料（`kSuitMats`），供「材料计算器」使用。
library;

import 'package:flutter/foundation.dart';

/// 套装档位（75 / 85 / 95）。
const List<String> kSuitLvKeys = ['75', '85', '95'];

/// 标签配色（对应原型 `.tag-<catType>`）。
enum PetSuitCatColor { gold, cyan, green, blue, purple }

/// 一套宝宝套装。
@immutable
class PetSuit {
  const PetSuit({
    required this.name,
    required this.cat,
    required this.catColor,
    required this.icon,
    required this.fits,
    required this.levels,
    required this.parts,
  });

  /// 套装名，如「勇猛套装」。
  final String name;

  /// 分类，如「外功输出」。
  final String cat;

  /// 分类 tag 配色。
  final PetSuitCatColor catColor;

  /// 图标资产名（经 `TgIcon` 渲染，如 `sword`）。
  final String icon;

  /// 适配类型，如「勇猛性格」「外功型宝宝」。
  final List<String> fits;

  /// 各档位效果：档位（75/85/95）→ 件数效果列表。
  final Map<String, List<PetSuitEffect>> levels;

  /// 五件套部件（顺序：头饰 / 铠甲 / 项圈 / 利爪 / 玉佩）。
  final List<PetSuitPart> parts;
}

/// 件数效果（如 `2 件 / 外功攻击 +2%`）。
@immutable
class PetSuitEffect {
  const PetSuitEffect({required this.pieces, required this.text});

  /// 件数说明，如「2 件」「3 件」。
  final String pieces;

  /// 效果文案，如「外功攻击 +2%」。
  final String text;
}

/// 单件部件（属性随档位：三档三值）。
@immutable
class PetSuitPart {
  const PetSuitPart({
    required this.slot,
    required this.name,
    required this.attr,
    required this.sub,
  });

  /// 部位，如「头饰」「铠甲」「项圈」「利爪」「玉佩」。
  final String slot;

  /// 部件名，如「赤焰·裂空盔」。
  final String name;

  /// 主属性（三档）：[75 档, 85 档, 95 档]。
  final List<String> attr;

  /// 副词条（三档）。
  final List<String> sub;

  /// 主属性（指定档位）。
  String attrAt(int lvIndex) => attr[lvIndex];

  /// 副词条（指定档位）。
  String subAt(int lvIndex) => sub[lvIndex];
}

/// 材料类型：兑换整套 / 升星基础。
enum SuitMatKind { exchange, starBase }

/// 套装兑换 / 升星材料。
@immutable
class SuitMats {
  const SuitMats({required this.exchange, required this.starBase});

  /// 兑换整套所需（每部件消耗，整套 ×5）：档位 → [[材料, 单件数], ...]。
  final Map<String, List<SuitMatItem>> exchange;

  /// 升星每部件基础消耗，第 k 星需 count × k（整套 ×5）。
  final Map<String, List<SuitMatItem>> starBase;
}

/// 单个材料条目。
@immutable
class SuitMatItem {
  const SuitMatItem({required this.name, required this.count});

  final String name;
  final int count;
}

/// 六大性格套装（与原型 `SUITS` 一致）。
const List<PetSuit> kPetSuits = [
  PetSuit(
    name: '勇猛套装',
    cat: '外功输出',
    catColor: PetSuitCatColor.gold,
    icon: 'sword',
    fits: ['勇猛性格', '外功型宝宝'],
    levels: {
      '75': [
        PetSuitEffect(pieces: '2 件', text: '外功攻击 +2%'),
        PetSuitEffect(pieces: '3 件', text: '会心伤害 +6%，命中 +1%'),
      ],
      '85': [
        PetSuitEffect(pieces: '2 件', text: '外功攻击 +3%'),
        PetSuitEffect(pieces: '3 件', text: '会心伤害 +8%，命中 +2%'),
      ],
      '95': [
        PetSuitEffect(pieces: '2 件', text: '外功攻击 +4%'),
        PetSuitEffect(pieces: '3 件', text: '会心伤害 +11%，命中 +3%'),
      ],
    },
    parts: [
      PetSuitPart(slot: '头饰', name: '赤焰·裂空盔', attr: ['外功攻击 +62', '外功攻击 +86', '外功攻击 +118'], sub: ['力量 +8', '力量 +11', '力量 +15']),
      PetSuitPart(slot: '铠甲', name: '赤焰·吞霄甲', attr: ['外防 +44', '外防 +60', '外防 +82'], sub: ['体力 +10', '体力 +14', '体力 +19']),
      PetSuitPart(slot: '项圈', name: '赤焰·噬日圈', attr: ['命中 +36', '命中 +50', '命中 +68'], sub: ['会心 +3', '会心 +4', '会心 +6']),
      PetSuitPart(slot: '利爪', name: '赤焰·撕裂爪', attr: ['外功攻击 +78', '外功攻击 +108', '外功攻击 +148'], sub: ['外功 +15', '外功 +21', '外功 +29']),
      PetSuitPart(slot: '玉佩', name: '赤焰·狂战玉', attr: ['会心伤害 +4%', '会心伤害 +6%', '会心伤害 +8%'], sub: ['力量 +6', '力量 +9', '力量 +12']),
    ],
  ),
  PetSuit(
    name: '胆小套装',
    cat: '灵巧输出',
    catColor: PetSuitCatColor.cyan,
    icon: 'spark',
    fits: ['胆小性格', '身法流'],
    levels: {
      '75': [
        PetSuitEffect(pieces: '2 件', text: '命中 +2%'),
        PetSuitEffect(pieces: '3 件', text: '闪避 +4%，移动速度 +3%'),
      ],
      '85': [
        PetSuitEffect(pieces: '2 件', text: '命中 +3%'),
        PetSuitEffect(pieces: '3 件', text: '闪避 +6%，移动速度 +4%'),
      ],
      '95': [
        PetSuitEffect(pieces: '2 件', text: '命中 +4%'),
        PetSuitEffect(pieces: '3 件', text: '闪避 +8%，移动速度 +5%'),
      ],
    },
    parts: [
      PetSuitPart(slot: '头饰', name: '疾风·追风帽', attr: ['身法 +9', '身法 +12', '身法 +16'], sub: ['闪避 +14', '闪避 +19', '闪避 +26']),
      PetSuitPart(slot: '铠甲', name: '疾风·蝉翼衫', attr: ['闪避 +40', '闪避 +55', '闪避 +75'], sub: ['身法 +7', '身法 +10', '身法 +13']),
      PetSuitPart(slot: '项圈', name: '疾风·逐影圈', attr: ['命中 +42', '命中 +58', '命中 +79'], sub: ['命中 +5', '命中 +7', '命中 +9']),
      PetSuitPart(slot: '利爪', name: '疾风·无影爪', attr: ['外功攻击 +56', '外功攻击 +77', '外功攻击 +105'], sub: ['攻速 +2%', '攻速 +3%', '攻速 +4%']),
      PetSuitPart(slot: '玉佩', name: '疾风·游龙玉', attr: ['移动速度 +3%', '移动速度 +4%', '移动速度 +5%'], sub: ['身法 +5', '身法 +7', '身法 +10']),
    ],
  ),
  PetSuit(
    name: '谨慎套装',
    cat: '生存防护',
    catColor: PetSuitCatColor.green,
    icon: 'shield',
    fits: ['谨慎性格', '肉盾型宝宝'],
    levels: {
      '75': [
        PetSuitEffect(pieces: '2 件', text: '气血上限 +2%'),
        PetSuitEffect(pieces: '3 件', text: '受到伤害 -3%，外防 +1%'),
      ],
      '85': [
        PetSuitEffect(pieces: '2 件', text: '气血上限 +3%'),
        PetSuitEffect(pieces: '3 件', text: '受到伤害 -4%，外防 +2%'),
      ],
      '95': [
        PetSuitEffect(pieces: '2 件', text: '气血上限 +4%'),
        PetSuitEffect(pieces: '3 件', text: '受到伤害 -5%，外防 +3%'),
      ],
    },
    parts: [
      PetSuitPart(slot: '头饰', name: '玄龟·玄武盔', attr: ['外防 +48', '外防 +66', '外防 +90'], sub: ['体力 +9', '体力 +13', '体力 +17']),
      PetSuitPart(slot: '铠甲', name: '玄龟·重岳甲', attr: ['气血上限 +320', '气血上限 +440', '气血上限 +600'], sub: ['外防 +12', '外防 +17', '外防 +23']),
      PetSuitPart(slot: '项圈', name: '玄龟·盘石圈', attr: ['内防 +36', '内防 +50', '内防 +68'], sub: ['定力 +7', '定力 +10', '定力 +13']),
      PetSuitPart(slot: '利爪', name: '玄龟·碎岩爪', attr: ['外防 +40', '外防 +55', '外防 +75'], sub: ['格挡 +3%', '格挡 +4%', '格挡 +5%']),
      PetSuitPart(slot: '玉佩', name: '玄龟·镇岳玉', attr: ['受到伤害 -2%', '受到伤害 -3%', '受到伤害 -4%'], sub: ['体力 +8', '体力 +11', '体力 +15']),
    ],
  ),
  PetSuit(
    name: '精明套装',
    cat: '内功输出',
    catColor: PetSuitCatColor.blue,
    icon: 'calc',
    fits: ['精明性格', '内功型宝宝'],
    levels: {
      '75': [
        PetSuitEffect(pieces: '2 件', text: '内功攻击 +2%'),
        PetSuitEffect(pieces: '3 件', text: '技能触发概率 +3%'),
      ],
      '85': [
        PetSuitEffect(pieces: '2 件', text: '内功攻击 +3%'),
        PetSuitEffect(pieces: '3 件', text: '技能触发概率 +5%'),
      ],
      '95': [
        PetSuitEffect(pieces: '2 件', text: '内功攻击 +4%'),
        PetSuitEffect(pieces: '3 件', text: '技能触发概率 +7%'),
      ],
    },
    parts: [
      PetSuitPart(slot: '头饰', name: '灵犀·灵犀冠', attr: ['内功攻击 +58', '内功攻击 +80', '内功攻击 +110'], sub: ['灵气 +9', '灵气 +13', '灵气 +17']),
      PetSuitPart(slot: '铠甲', name: '灵犀·云纹衣', attr: ['内防 +40', '内防 +55', '内防 +75'], sub: ['灵气 +7', '灵气 +10', '灵气 +13']),
      PetSuitPart(slot: '项圈', name: '灵犀·凝露圈', attr: ['内功攻击 +46', '内功攻击 +63', '内功攻击 +86'], sub: ['气上限 +60', '气上限 +82', '气上限 +112']),
      PetSuitPart(slot: '利爪', name: '灵犀·摄魂爪', attr: ['内功攻击 +72', '内功攻击 +99', '内功攻击 +135'], sub: ['内功 +14', '内功 +20', '内功 +27']),
      PetSuitPart(slot: '玉佩', name: '灵犀·慧心玉', attr: ['技能触发概率 +2%', '技能触发概率 +3%', '技能触发概率 +4%'], sub: ['灵气 +6', '灵气 +8', '灵气 +11']),
    ],
  ),
  PetSuit(
    name: '忠诚套装',
    cat: '守护辅助',
    catColor: PetSuitCatColor.purple,
    icon: 'paw',
    fits: ['忠诚性格', '守护型宝宝'],
    levels: {
      '75': [
        PetSuitEffect(pieces: '2 件', text: '内外防 +2%'),
        PetSuitEffect(pieces: '3 件', text: '主人受到伤害 -2%'),
      ],
      '85': [
        PetSuitEffect(pieces: '2 件', text: '内外防 +3%'),
        PetSuitEffect(pieces: '3 件', text: '主人受到伤害 -3%'),
      ],
      '95': [
        PetSuitEffect(pieces: '2 件', text: '内外防 +4%'),
        PetSuitEffect(pieces: '3 件', text: '主人受到伤害 -4%'),
      ],
    },
    parts: [
      PetSuitPart(slot: '头饰', name: '守望·忠勇盔', attr: ['内外防 +34', '内外防 +47', '内外防 +64'], sub: ['定力 +8', '定力 +11', '定力 +15']),
      PetSuitPart(slot: '铠甲', name: '守望·铁卫甲', attr: ['气血上限 +280', '气血上限 +385', '气血上限 +525'], sub: ['外防 +10', '外防 +14', '外防 +19']),
      PetSuitPart(slot: '项圈', name: '守望·护主圈', attr: ['主人受伤减免 +1.5%', '主人受伤减免 +2%', '主人受伤减免 +2.5%'], sub: ['定力 +6', '定力 +9', '定力 +12']),
      PetSuitPart(slot: '利爪', name: '守望·警觉爪', attr: ['闪避 +30', '闪避 +41', '闪避 +56'], sub: ['身法 +6', '身法 +9', '身法 +12']),
      PetSuitPart(slot: '玉佩', name: '守望·赤诚玉', attr: ['内外防 +5%', '内外防 +7%', '内外防 +9%'], sub: ['体力 +7', '体力 +10', '体力 +13']),
    ],
  ),
  PetSuit(
    name: '内敛套装',
    cat: '爆发会心',
    catColor: PetSuitCatColor.gold,
    icon: 'flame',
    fits: ['内敛性格', '会心流宝宝'],
    levels: {
      '75': [
        PetSuitEffect(pieces: '2 件', text: '会心 +2%'),
        PetSuitEffect(pieces: '3 件', text: '会心防御 +6%，气上限 +3%'),
      ],
      '85': [
        PetSuitEffect(pieces: '2 件', text: '会心 +3%'),
        PetSuitEffect(pieces: '3 件', text: '会心防御 +8%，气上限 +4%'),
      ],
      '95': [
        PetSuitEffect(pieces: '2 件', text: '会心 +4%'),
        PetSuitEffect(pieces: '3 件', text: '会心防御 +10%，气上限 +5%'),
      ],
    },
    parts: [
      PetSuitPart(slot: '头饰', name: '惊雷·敛雷冠', attr: ['会心 +22', '会心 +30', '会心 +41'], sub: ['灵气 +8', '灵气 +11', '灵气 +15']),
      PetSuitPart(slot: '铠甲', name: '惊雷·暗锋衣', attr: ['会心防御 +30', '会心防御 +41', '会心防御 +56'], sub: ['气上限 +55', '气上限 +76', '气上限 +104']),
      PetSuitPart(slot: '项圈', name: '惊雷·惊蛰圈', attr: ['会心 +18', '会心 +25', '会心 +34'], sub: ['会心伤害 +2%', '会心伤害 +3%', '会心伤害 +4%']),
      PetSuitPart(slot: '利爪', name: '惊雷·破军爪', attr: ['会心 +26', '会心 +36', '会心 +49'], sub: ['会心 +4', '会心 +6', '会心 +8']),
      PetSuitPart(slot: '玉佩', name: '惊雷·雷引玉', attr: ['气上限 +4%', '气上限 +5%', '气上限 +6%'], sub: ['会心防御 +5', '会心防御 +7', '会心防御 +10']),
    ],
  ),
];

/// 套装兑换 / 升星材料（与原型 `SUIT_MATS` 一致）。
const SuitMats kSuitMats = SuitMats(
  exchange: {
    '85': [
      SuitMatItem(name: '玄铁令', count: 8),
      SuitMatItem(name: '锻魂石', count: 4),
      SuitMatItem(name: '银两', count: 150000),
    ],
    '95': [
      SuitMatItem(name: '赤金令', count: 16),
      SuitMatItem(name: '洗魂髓', count: 6),
      SuitMatItem(name: '银两', count: 400000),
    ],
  },
  starBase: {
    '75': [
      SuitMatItem(name: '套装精魄', count: 6),
      SuitMatItem(name: '寒铁', count: 3),
      SuitMatItem(name: '银两', count: 25000),
    ],
    '85': [
      SuitMatItem(name: '套装精魄', count: 10),
      SuitMatItem(name: '玄铁', count: 5),
      SuitMatItem(name: '银两', count: 60000),
    ],
    '95': [
      SuitMatItem(name: '套装精魄', count: 16),
      SuitMatItem(name: '赤铁', count: 8),
      SuitMatItem(name: '银两', count: 150000),
    ],
  },
);

/// 材料计算输入。
@immutable
class SuitMatCalcInput {
  const SuitMatCalcInput({
    required this.lv,
    required this.currentStar,
    required this.withExchange,
  });

  /// 档位（75 / 85 / 95）。
  final String lv;

  /// 当前星级（0~4，升到 5 星）。
  final int currentStar;

  /// 是否计入兑换整套材料。
  final bool withExchange;
}

/// 材料计算结果：兑换行 / 升星各行 / 合计。
@immutable
class SuitMatCalcResult {
  const SuitMatCalcResult({
    required this.exchange,
    required this.starRows,
    required this.total,
  });

  /// 兑换整套材料（每部件消耗 ×5；不计入则空）。
  final List<SuitMatItem> exchange;

  /// 升星各星级消耗：下标 k 对应「k+1★ → (k+1)★」的消耗。
  final List<SuitMatStarRow> starRows;

  /// 合计消耗。
  final List<SuitMatItem> total;
}

/// 单星级升星消耗。
@immutable
class SuitMatStarRow {
  const SuitMatStarRow({required this.star, required this.mats});

  /// 目标星级（1~5）。
  final int star;

  final List<SuitMatItem> mats;
}

/// 计算材料消耗（与原型 `suitMatsCalc` 一致）：
/// - 兑换：每部件消耗 ×5（整套）；
/// - 升星：第 k 星消耗 = 基础消耗 × k × 5（整套）。
SuitMatCalcResult suitMatsCalc(SuitMatCalcInput input) {
  final lv = input.lv;
  final exchange = input.withExchange
      ? (kSuitMats.exchange[lv] ?? const <SuitMatItem>[])
          .map((m) => SuitMatItem(name: m.name, count: m.count * 5))
          .toList(growable: false)
      : const <SuitMatItem>[];

  final base = kSuitMats.starBase[lv] ?? const <SuitMatItem>[];
  final rows = <SuitMatStarRow>[];
  for (var k = input.currentStar + 1; k <= 5; k++) {
    rows.add(SuitMatStarRow(
      star: k,
      mats: base
          .map((m) => SuitMatItem(name: m.name, count: m.count * k * 5))
          .toList(growable: false),
    ));
  }

  final total = <String, int>{};
  void add(List<SuitMatItem> items) {
    for (final m in items) {
      total[m.name] = (total[m.name] ?? 0) + m.count;
    }
  }

  add(exchange);
  for (final r in rows) {
    add(r.mats);
  }

  return SuitMatCalcResult(
    exchange: exchange,
    starRows: rows,
    total: total.entries
        .map((e) => SuitMatItem(name: e.key, count: e.value))
        .toList(growable: false),
  );
}

/// 大数字格式化：≥1 万显示 `x.x万`（整数则不带小数），否则原样。
String suitFmtCount(int n) {
  if (n >= 10000) {
    final wan = n / 10000;
    final text = n % 10000 == 0 ? wan.toStringAsFixed(0) : wan.toStringAsFixed(1);
    return '$text万';
  }
  return '$n';
}
