/// 职业武道 —— 领域模型与数据（与 UI 原型 `WUDAO_PATHS` / `WUDAO_TREES` 一致）。
///
/// 两条武道路线（攻伐之道 / 御守之道），每条 4 个「重」（一重~四重）；
/// 每重对应一棵 7 节点技能树（`WUDAO_TREES[treeKey]`），
/// 首个节点为金框「核心节点」。
library;

import 'package:flutter/foundation.dart';

/// 一棵技能树的单个节点（`treeSVG` 中的盒子）。
@immutable
class WudaoNode {
  const WudaoNode({required this.name, required this.effect});

  /// 节点名（如 锋刃）。
  final String name;

  /// 效果（如 攻击 +8）。
  final String effect;
}

/// 一条武道路线中的「一重」。
@immutable
class WudaoTier {
  const WudaoTier({
    required this.name,
    required this.effect,
    required this.tree,
  });

  /// 重名（如 锋芒 / 铁壁）。
  final String name;

  /// 档位总效果（如 攻击 +2%）。
  final String effect;

  /// 技能树数据（`WUDAO_TREES[t.tree]`，7 节点）。
  final List<WudaoNode> tree;
}

/// 一条武道路线（攻伐 / 御守）。
@immutable
class WudaoPath {
  const WudaoPath({
    required this.name,
    required this.icon,
    required this.sub,
    required this.rec,
    required this.tiers,
  });

  final String name;

  /// 图标资产名（`sword` / `shield`）。
  final String icon;

  /// 路线简述。
  final String sub;

  /// 推荐度（1~5 星）。
  final int rec;

  /// 一重 ~ 四重。
  final List<WudaoTier> tiers;
}

/// 重数标签（`.p-lv`）。
const List<String> kWudaoTierCn = ['一重', '二重', '三重', '四重'];

/// 两条武道路线（对应原型 `WUDAO_PATHS`）。
const List<WudaoPath> kWudaoPaths = [
  WudaoPath(
    name: '攻伐之道',
    icon: 'sword',
    sub: '输出最大化路线 · 适合副本与群战',
    rec: 5,
    tiers: [
      WudaoTier(
        name: '锋芒',
        effect: '攻击 +2%',
        tree: [
          WudaoNode(name: '武道 · 锋芒', effect: '核心节点 · 开启攻伐'),
          WudaoNode(name: '锋刃', effect: '攻击 +8'),
          WudaoNode(name: '锐气', effect: '属性攻 +5'),
          WudaoNode(name: '破军', effect: '攻击 +12'),
          WudaoNode(name: '蚀甲', effect: '忽视防御 +5'),
          WudaoNode(name: '聚气', effect: '气上限 +150'),
          WudaoNode(name: '锐不可当', effect: '属性攻 +8'),
        ],
      ),
      WudaoTier(
        name: '破势',
        effect: '会心 +1.5%',
        tree: [
          WudaoNode(name: '武道 · 破势', effect: '核心节点 · 强化会心'),
          WudaoNode(name: '破防', effect: '忽视防御 +8'),
          WudaoNode(name: '锐目', effect: '会心 +5'),
          WudaoNode(name: '裂甲', effect: '忽视防御 +12'),
          WudaoNode(name: '弱点洞察', effect: '命中 +15'),
          WudaoNode(name: '锐目 · 极', effect: '会心 +8'),
          WudaoNode(name: '一击即中', effect: '会心伤害 +6%'),
        ],
      ),
      WudaoTier(
        name: '穿云',
        effect: '忽视防御 +3%',
        tree: [
          WudaoNode(name: '武道 · 穿云', effect: '核心节点 · 强化穿透'),
          WudaoNode(name: '穿透', effect: '忽视抗性 +8'),
          WudaoNode(name: '迅疾', effect: '攻击速度 +3%'),
          WudaoNode(name: '贯日', effect: '忽视抗性 +12'),
          WudaoNode(name: '破空', effect: '穿透伤害 +4%'),
          WudaoNode(name: '疾风', effect: '攻速 +4%'),
          WudaoNode(name: '连珠', effect: '连击概率 +3%'),
        ],
      ),
      WudaoTier(
        name: '惊雷',
        effect: '技能伤害 +4%',
        tree: [
          WudaoNode(name: '武道 · 惊雷', effect: '核心节点 · 终极输出'),
          WudaoNode(name: '雷殛', effect: '技能伤害 +4%'),
          WudaoNode(name: '灭世', effect: '全属性攻 +5%'),
          WudaoNode(name: '雷霆万钧', effect: '技能伤害 +6%'),
          WudaoNode(name: '天雷破', effect: '爆发技 +8%'),
          WudaoNode(name: '万法归宗', effect: '全属性攻 +8%'),
          WudaoNode(name: '势如破竹', effect: '伤害递增 +3%'),
        ],
      ),
    ],
  ),
  WudaoPath(
    name: '御守之道',
    icon: 'shield',
    sub: '生存向路线 · 适合帮战与持久战',
    rec: 4,
    tiers: [
      WudaoTier(
        name: '铁壁',
        effect: '受伤 -1.5%',
        tree: [
          WudaoNode(name: '武道 · 铁壁', effect: '核心节点 · 开启御守'),
          WudaoNode(name: '坚甲', effect: '内外防 +10'),
          WudaoNode(name: '体魄', effect: '血上限 +300'),
          WudaoNode(name: '金钟', effect: '外防 +15'),
          WudaoNode(name: '铁布衫', effect: '内防 +15'),
          WudaoNode(name: '龙象', effect: '血上限 +450'),
          WudaoNode(name: '生生不息', effect: '回血 1% / 5 秒'),
        ],
      ),
      WudaoTier(
        name: '盘石',
        effect: '内外防 +2%',
        tree: [
          WudaoNode(name: '武道 · 盘石', effect: '核心节点 · 强化减伤'),
          WudaoNode(name: '稳如山', effect: '受伤 -2%'),
          WudaoNode(name: '卸力', effect: '格挡 +5%'),
          WudaoNode(name: '不动明王', effect: '受伤 -3%'),
          WudaoNode(name: '卸甲', effect: '被暴击 -6%'),
          WudaoNode(name: '铁壁格挡', effect: '格挡 +7%'),
          WudaoNode(name: '四两拨千斤', effect: '格挡反伤 +5%'),
        ],
      ),
      WudaoTier(
        name: '回春',
        effect: '受治疗 +3%',
        tree: [
          WudaoNode(name: '武道 · 回春', effect: '核心节点 · 强化恢复'),
          WudaoNode(name: '自愈', effect: '受治疗 +8%'),
          WudaoNode(name: '韧性', effect: '控制减免 +6%'),
          WudaoNode(name: '枯木逢春', effect: '受治疗 +12%'),
          WudaoNode(name: '春泥', effect: '持续回复 +2%'),
          WudaoNode(name: '百折不挠', effect: '控制减免 +9%'),
          WudaoNode(name: '宁神', effect: '眩晕减免 +10%'),
        ],
      ),
      WudaoTier(
        name: '不灭',
        effect: '团队减伤 +2%',
        tree: [
          WudaoNode(name: '武道 · 不灭', effect: '核心节点 · 终极守护'),
          WudaoNode(name: '守护', effect: '团队减伤 +2%'),
          WudaoNode(name: '反震', effect: '反伤 +6%'),
          WudaoNode(name: '铜墙铁壁', effect: '团队减伤 +3%'),
          WudaoNode(name: '庇护所', effect: '濒死护盾 +10%'),
          WudaoNode(name: '以牙还牙', effect: '反伤 +8%'),
          WudaoNode(name: '荆棘甲', effect: '反伤减速'),
        ],
      ),
    ],
  ),
];
