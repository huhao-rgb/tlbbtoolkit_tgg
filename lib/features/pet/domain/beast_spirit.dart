/// 兽灵图鉴 —— 领域模型与数据（与 UI 原型 v1.13.0 `v-beast-index` 一致）。
///
/// 兽灵以「珍兽技能」为单位划分：珍兽觉醒缔约兽灵后，对应技能获得强化。
/// 兽灵技能共 **20 级 · 7 阶**（一阶 1-3 级 → 七阶 20 级），每只兽灵含
/// **两个效果位**：效果一 4 级解锁、效果二 10 级解锁，部分效果在珍兽进入
/// 「怒意三阶」抽取到该技能时触发。
///
/// 6 只兽灵中破御 / 破胆已收录 7 阶完整数据（TLBB怀旧攻略小程序 · 用户核验），
/// 拼命 / 痛击 / 连击 / 灵动逐阶数值待补，仅收录攻略共识。
///
/// 文案中的 `<b>…</b>`（金强调）与 `<i>…</i>`（未解锁占位）由表现层解析。
library;

import 'package:flutter/foundation.dart';

/// 兽灵数据完整度（对应原型标题行右侧 tag）。
enum BeastSpiritStatus {
  /// 已收录 7 阶逐阶数据（`.tag-gold`）。
  complete('完整数据'),

  /// 逐阶数值待补，仅收录攻略共识（`.tag`）。
  pending('待补');

  const BeastSpiritStatus(this.label);

  /// tag 文案。
  final String label;
}

/// 单个阶位的兽灵效果。
@immutable
class BeastSpiritTier {
  const BeastSpiritTier({
    required this.name,
    required this.lv,
    required this.dec,
    required this.effect1,
    required this.effect2,
  });

  /// 阶位名（如 `一阶`）。
  final String name;

  /// 等级区间（如 `1-3 级`）。
  final String lv;

  /// 阶位说明（含 `<b>…</b>` 金强调）。
  final String dec;

  /// 兽灵效果一（4 级解锁；含 `<b>…</b>` / `<i>…</i>`）。
  final String effect1;

  /// 兽灵效果二（10 级解锁；含 `<b>…</b>` / `<i>…</i>`）。
  final String effect2;
}

/// 一只兽灵（以珍兽技能为单位）。
@immutable
class BeastSpirit {
  const BeastSpirit({
    required this.id,
    required this.name,
    required this.sub,
    required this.status,
    this.tiers = const [],
    this.pendingBody = '',
    this.pendingNote = '',
  });

  /// 稳定 id（对应原型 `#poyu` / `#podan` / …）。
  final String id;

  /// 名称（如 `破御兽灵`）。
  final String name;

  /// 一句话定位（如 `破防 · 会心削减`）。
  final String sub;

  /// 数据完整度。
  final BeastSpiritStatus status;

  /// 7 阶数据；[status] 为 [BeastSpiritStatus.pending] 时为空。
  final List<BeastSpiritTier> tiers;

  /// 待补正文（含 `<b>…</b>`）；仅 [BeastSpiritStatus.pending] 使用。
  final String pendingBody;

  /// 待补攻略注（`※` 起头，走 `.soul-fx` 样式）；仅待补兽灵使用。
  final String pendingNote;

  /// 是否已收录 7 阶完整数据。
  bool get isComplete => status == BeastSpiritStatus.complete;
}

/// 阶位结构中的一阶（对应「阶位结构 · 20 级 7 阶」进度条）。
@immutable
class BeastTierStep {
  const BeastTierStep(this.name, this.lv);

  /// 阶位名（如 `一阶`）。
  final String name;

  /// 等级区间（如 `1-3 级`）。
  final String lv;
}

/// 阶位结构：20 级 7 阶。
const List<BeastTierStep> kBeastTierSteps = [
  BeastTierStep('一阶', '1-3 级'),
  BeastTierStep('二阶', '4-6 级'),
  BeastTierStep('三阶', '7-9 级'),
  BeastTierStep('四阶', '10-12 级'),
  BeastTierStep('五阶', '13-15 级'),
  BeastTierStep('六阶', '16-19 级'),
  BeastTierStep('七阶', '20 级'),
];

/// 兽灵技能图鉴（手风琴顺序与原型一致）。
const List<BeastSpirit> kBeastSpirits = [
  BeastSpirit(
    id: 'poyu',
    name: '破御兽灵',
    sub: '破防 · 会心削减',
    status: BeastSpiritStatus.complete,
    tiers: [
      BeastSpiritTier(
        name: '一阶',
        lv: '1-3 级',
        dec: '额外降低目标 <b>2%</b> 的会心防御',
        effect1: '<i>4 级解锁</i>',
        effect2: '<i>10 级解锁</i>',
      ),
      BeastSpiritTier(
        name: '二阶',
        lv: '4-6 级',
        dec: '额外降低目标 <b>4%</b> 的会心防御',
        effect1: '珍兽进入<b>怒意三阶</b>抽取到此技能时，使主人会心攻击和会心防御 <b>+5%</b>',
        effect2: '<i>10 级解锁</i>',
      ),
      BeastSpiritTier(
        name: '三阶',
        lv: '7-9 级',
        dec: '额外降低目标 <b>8%</b> 的会心防御',
        effect1: '珍兽进入<b>怒意三阶</b>抽取到此技能时，使主人会心攻击和会心防御 <b>+5%</b>',
        effect2: '<i>10 级解锁</i>',
      ),
      BeastSpiritTier(
        name: '四阶',
        lv: '10-12 级',
        dec: '额外降低目标 <b>16%</b> 的会心防御',
        effect1: '怒意三阶抽取到此技能时，主人会心攻击和会心防御 <b>+15%</b>',
        effect2: '怒意三阶抽取到此技能时，给主人一个<b>免疫 1 次</b>会心伤害的护盾，持续 <b>3 秒</b>',
      ),
      BeastSpiritTier(
        name: '五阶',
        lv: '13-15 级',
        dec: '额外降低目标 <b>16%</b> 的会心防御',
        effect1: '怒意三阶抽取到此技能时，主人会心攻击和会心防御 <b>+15%</b>',
        effect2: '给主人一个<b>免疫 2 次</b>会心伤害的护盾，持续 <b>4 秒</b>',
      ),
      BeastSpiritTier(
        name: '六阶',
        lv: '16-19 级',
        dec: '额外降低目标 <b>16%</b> 的会心防御',
        effect1: '怒意三阶抽取到此技能时，主人会心攻击和会心防御 <b>+15%</b>',
        effect2: '给主人一个<b>免疫 3 次</b>会心伤害的护盾，持续 <b>5 秒</b>',
      ),
      BeastSpiritTier(
        name: '七阶',
        lv: '20 级',
        dec: '额外降低目标 <b>16%</b> 的会心防御',
        effect1: '怒意三阶抽取到此技能时，主人会心攻击和会心防御 <b>+15%</b>',
        effect2: '给主人一个<b>免疫 5 次</b>会心伤害的护盾，持续 <b>8 秒</b>',
      ),
    ],
  ),
  BeastSpirit(
    id: 'podan',
    name: '破胆兽灵',
    sub: '普攻附伤 · 增伤',
    status: BeastSpiritStatus.complete,
    tiers: [
      BeastSpiritTier(
        name: '一阶',
        lv: '1-3 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>1%</b> 的伤害',
        effect1: '<i>4 级解锁</i>',
        effect2: '<i>10 级解锁</i>',
      ),
      BeastSpiritTier(
        name: '二阶',
        lv: '4-6 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>2%</b> 的伤害',
        effect1: '此珍兽出战时，主人对拥有破胆的目标造成的伤害提升 <b>1%</b>',
        effect2: '<i>10 级解锁</i>',
      ),
      BeastSpiritTier(
        name: '三阶',
        lv: '7-9 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>4%</b> 的伤害',
        effect1: '此珍兽出战时，主人对拥有破胆的目标造成的伤害提升 <b>1%</b>',
        effect2: '<i>10 级解锁</i>',
      ),
      BeastSpiritTier(
        name: '四阶',
        lv: '10-12 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>10%</b> 的伤害',
        effect1: '此珍兽出战时，主人对拥有破胆的目标造成的伤害提升 <b>2%</b>',
        effect2:
            '主人对拥有破胆的目标造成的伤害提升 <b>1%</b>；<b>怒意三阶</b>抽取到此技能时，额外提升 <b>1%</b>',
      ),
      BeastSpiritTier(
        name: '五阶',
        lv: '13-15 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>10%</b> 的伤害',
        effect1: '此珍兽出战时，主人对拥有破胆的目标造成的伤害提升 <b>2%</b>',
        effect2:
            '主人对拥有破胆的目标造成的伤害提升 <b>1%</b>；<b>怒意三阶</b>抽取到此技能时，额外提升 <b>2%</b>',
      ),
      BeastSpiritTier(
        name: '六阶',
        lv: '16-19 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>10%</b> 的伤害',
        effect1: '此珍兽出战时，主人对拥有破胆的目标造成的伤害提升 <b>2%</b>',
        effect2:
            '主人对拥有破胆的目标造成的伤害提升 <b>2%</b>；<b>怒意三阶</b>抽取到此技能时，额外提升 <b>2%</b>',
      ),
      BeastSpiritTier(
        name: '七阶',
        lv: '20 级',
        dec: '珍兽对拥有<b>破胆</b>效果的目标造成普通攻击伤害时，额外附带一次普通攻击 <b>10%</b> 的伤害',
        effect1: '此珍兽出战时，主人对拥有破胆的目标造成的伤害提升 <b>2%</b>',
        effect2:
            '主人对拥有破胆的目标造成的伤害提升 <b>2%</b>；<b>怒意三阶</b>抽取到此技能时，额外提升 <b>4%</b>',
      ),
    ],
  ),
  BeastSpirit(
    id: 'pinming',
    name: '拼命兽灵',
    sub: '勇猛 · 攻击强化',
    status: BeastSpiritStatus.pending,
    pendingBody:
        '<b>版本核心技能</b>：兽灵强化下为输出宝宝必备。与连击、灵动并称输出宝宝<b>核心三件套</b>'
        '（拼命 + 连击 + 灵动），勇猛性格触发频率最高。',
    pendingNote: '※ 贴吧攻略共识：拼命为兽灵版本输出宝宝第一优先级',
  ),
  BeastSpirit(
    id: 'tongji',
    name: '痛击兽灵',
    sub: '胆小 · 内功输出',
    status: BeastSpiritStatus.pending,
    pendingBody:
        '内功宝宝的主要输出技能，内功宝宝的输出很大比率来自痛击。胆小性格触发率高；'
        '兽灵强化后为内功流（凝神/痛击向）核心。',
    pendingNote: '※ 适配：内功珍兽 + 内功门派主人（武当/逍遥/星宿）',
  ),
  BeastSpirit(
    id: 'lianji',
    name: '连击兽灵',
    sub: '勇猛 · 外功输出',
    status: BeastSpiritStatus.pending,
    pendingBody:
        '外功输出宝宝常用兽灵：外功拼命输出宝宝带连击兽灵较多，配合拼命形成高频攻击链。'
        '谨慎体力宝宝一般不选。',
    pendingNote: '※ 贴吧讨论：外功输出向常用，PVE 收益直接',
  ),
  BeastSpirit(
    id: 'lingdong',
    name: '灵动兽灵',
    sub: '通用 · 生存减伤',
    status: BeastSpiritStatus.pending,
    pendingBody:
        '生存向兽灵：减少珍兽受到的伤害，提升存活率。「灵动 + 拼命」为经典组合——'
        '高输出宝宝生存压力大时必备，50 级兽灵可酌情替换。',
    pendingNote: '※ 贴吧共识：灵动拼命必备；谨慎体力宝宝核心（打怒 + 灵动）',
  ),
];

/// 图鉴顶部说明（原型 `.calc-note`，含 `<b>…</b>` 金强调）。
const String kBeastIndexIntroNote =
    '兽灵以<b>珍兽技能</b>为单位划分：珍兽觉醒缔约兽灵后，对应技能获得强化。'
    '兽灵技能共 <b>20 级 · 7 阶</b>（一阶 1-3 级 → 七阶 20 级），每只兽灵含'
    '<b>两个效果位</b>：效果一 4 级解锁、效果二 10 级解锁，部分效果在珍兽进入'
    '<b>怒意三阶</b>抽取到该技能时触发。'
    '（破御、破胆数据：TLBB怀旧攻略小程序 · 用户核验；其余来自社区实测与攻略共识，'
    '逐级数值以游戏内为准）';

/// 图鉴底部说明（原型 `.calc-note`）。
const String kBeastIndexFootNote =
    '※ 拼命/痛击/连击/灵动的逐阶数值尚未收录完整（官方未公布全部表格）；'
    '破御、破胆 7 阶数据经用户从小程序「TLBB怀旧攻略」核验，可直接参考。'
    '破御礼包例：「破御斩虚兽灵自选礼包」（2026-02 官方活动，叶子猪）。';
