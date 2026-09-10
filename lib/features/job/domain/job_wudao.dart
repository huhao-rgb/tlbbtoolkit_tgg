/// 职业武道 —— 领域模型与数据（与 UI 原型 `WUDAO` 一致）。
///
/// 按门派收录官网「武道」流派数据（数据源：畅游官网资料站门派专题）：
/// - 每个门派 1~2 个流派（school），每个流派有流派被动（pd：名/效果/图标）；
/// - 每个流派下分若干「重」（layers，武道一重~四重），同层择一、每重 5 级；
/// - 每个节点为 [名称, 效果, 图标路径]。
/// - 慕容 / 曼陀山庄暂无官网武道数据（页面显示占位提示）。
library;

import 'package:flutter/foundation.dart';

/// 流派被动（`WUDAO[].pd`）。
@immutable
class WudaoPassive {
  const WudaoPassive({required this.name, required this.desc, this.icon});

  final String name;

  /// 被动效果描述。
  final String desc;

  /// 图标资源路径（可空）。
  final String? icon;
}

/// 武道节点（`layers[][i]`：名称 / 效果 / 图标）。
@immutable
class WudaoNode {
  const WudaoNode({required this.name, required this.effect, this.icon});

  final String name;

  /// 效果（如 貂蝉拜月的内功攻击额外增加100%）。
  final String effect;

  /// 图标资源路径（可空）。
  final String? icon;
}

/// 一「重」（layers[i]，同层择一、每重 5 级）。
@immutable
class WudaoLayer {
  const WudaoLayer({required this.nodes});

  final List<WudaoNode> nodes;
}

/// 一个武道流派。
@immutable
class WudaoSchool {
  const WudaoSchool({required this.name, required this.passive, required this.layers});

  /// 流派名（如 专心治疗）。
  final String name;

  /// 流派被动。
  final WudaoPassive passive;

  /// 各重节点列表（layers 下标 = 重序号）。
  final List<WudaoLayer> layers;
}

/// 重数标签（`.wd-lname`）。
const List<String> kWudaoTierCn = ['一重', '二重', '三重', '四重'];

/// 按门派武道数据（对应原型 `WUDAO`）。
const Map<String, List<WudaoSchool>> kWudao = {
  'emei': [
    WudaoSchool(
      name: '专心治疗',
      passive: WudaoPassive(name: '医者仁心', desc: '清心普善咒和冲虚养气对其他玩家释放时，有5%几率清除延年益寿的冷却时间。', icon: 'assets/wudao_icons/emei_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '拜月·神威', effect: '貂蝉拜月的内功攻击额外增加100%', icon: 'assets/wudao_icons/emei_s0_l0_n0.webp'), WudaoNode(name: '盈裕太渊', effect: '冲虚养气增加的血量提高25%', icon: 'assets/wudao_icons/emei_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '甘木灵佑', effect: '延年益寿护体的生命值增加100%', icon: 'assets/wudao_icons/emei_s0_l1_n0.webp'), WudaoNode(name: '净繁芜', effect: '延年益寿持续期间，有50%的几率免疫控制', icon: 'assets/wudao_icons/emei_s0_l1_n1.webp'), WudaoNode(name: '凝神皈心', effect: '护心决冷却时间减少100秒', icon: 'assets/wudao_icons/emei_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '风清月朗', effect: '释放清心普善咒有10%概率减少春花秋月2秒冷却时间', icon: 'assets/wudao_icons/emei_s0_l2_n0.webp'), WudaoNode(name: '风摧木鸣', effect: '每次受到攻击额外增加10点怒气', icon: 'assets/wudao_icons/emei_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '花满闲潭', effect: '春花秋月对友方目标的回血量额外提升50%', icon: 'assets/wudao_icons/emei_s0_l3_n0.webp'), WudaoNode(name: '妙手回天', effect: '回天术每2秒额外回复血上限1%的血量', icon: 'assets/wudao_icons/emei_s0_l3_n1.webp'), WudaoNode(name: '桃李春风', effect: '佛光普照额外回复目标血上限1%，同时耗蓝量增加30%', icon: 'assets/wudao_icons/emei_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '能打能奶',
      passive: WudaoPassive(name: '琵琶声停', desc: '行复止：昭君出塞标记目标时，额外给目标1个10秒减速50%的状态；青冢月：若目标身上已有减速效果，则给目标1个4秒的定身状态。但同时昭君出塞标记伤害降低2%', icon: 'assets/wudao_icons/emei_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '拜月·神威', effect: '貂蝉拜月的内功攻击额外增加100%', icon: 'assets/wudao_icons/emei_s1_l0_n0.webp'), WudaoNode(name: '遮云蔽月', effect: '障眼法触发失明的概率增加5%', icon: 'assets/wudao_icons/emei_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '半阙商歌', effect: '金顶绵掌增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/emei_s1_l1_n0.webp'), WudaoNode(name: '筝鸣裂帛', effect: '金顶绵掌的技能伤害额外增加50%', icon: 'assets/wudao_icons/emei_s1_l1_n1.webp'), WudaoNode(name: '空山凝云', effect: '金顶绵掌降低移动速度修改为70%', icon: 'assets/wudao_icons/emei_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '轮弦繁促', effect: '西子捧心命中目标有10%概率清除该技能的冷却时间', icon: 'assets/wudao_icons/emei_s1_l2_n0.webp'), WudaoNode(name: '杀机四伏', effect: '金顶绵掌每次造成伤害有25%概率减少九阴神爪30秒冷却时间', icon: 'assets/wudao_icons/emei_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '西子叹', effect: '西子捧心的伤害增加40%', icon: 'assets/wudao_icons/emei_s1_l3_n0.webp'), WudaoNode(name: '月寒衾', effect: '春花秋月对敌方目标造成伤害时，增加的内攻攻击额外增加100%', icon: 'assets/wudao_icons/emei_s1_l3_n1.webp'), WudaoNode(name: '幽咽泉流', effect: '九阴神爪附带1个持续10秒，减速50%的减速状态', icon: 'assets/wudao_icons/emei_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'gaibang': [
    WudaoSchool(
      name: '循环输出',
      passive: WudaoPassive(name: '且醉且狂', desc: '消耗连击段的单体输出技能伤害增加15%，控鹤式技能暴击时额外增加10%概率获得2个连击段', icon: 'assets/wudao_icons/gaibang_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '蟠龙击·神威', effect: '蟠龙击增加的外功攻击额外增加100%', icon: 'assets/wudao_icons/gaibang_s0_l0_n0.webp'), WudaoNode(name: '龙息', effect: '青龙出水触发回复血量的概率增加20%', icon: 'assets/wudao_icons/gaibang_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '破阵急奏', effect: '冲阵斩将的冷却时间减少10秒', icon: 'assets/wudao_icons/gaibang_s0_l1_n0.webp'), WudaoNode(name: '烟锁迷阵', effect: '冲阵斩将命中目标有50%的概率使目标进入僵硬状态，移动速度减少60%，持续10秒', icon: 'assets/wudao_icons/gaibang_s0_l1_n1.webp'), WudaoNode(name: '揽杯倾盏', effect: '青龙出水触发回复血量，有35%概率额外回复自身血上限5%的血量', icon: 'assets/wudao_icons/gaibang_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '虬龙返', effect: '蟠龙击击中目标有30%的概率额外获得1个连击点', icon: 'assets/wudao_icons/gaibang_s0_l2_n0.webp'), WudaoNode(name: '醉里腾挪', effect: '每次闪避攻击有50%的概率获得1个连击点', icon: 'assets/wudao_icons/gaibang_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '酩酊龙舞', effect: '飞龙在天一段伤害增加500点，二段伤害增加750点，三段伤害增加1000点', icon: 'assets/wudao_icons/gaibang_s0_l3_n0.webp'), WudaoNode(name: '酣然一醉', effect: '飞龙在天一段最终造成的伤害提高为115%，二段最终造成的伤害提高为140%，三段最终造成的伤害提高为165%', icon: 'assets/wudao_icons/gaibang_s0_l3_n1.webp'), WudaoNode(name: '吞风饮雨', effect: '飞龙在天在命中目标时，一段能减少青龙出水和棒打狗头5秒冷却时间，二段能减少青龙出水和棒打狗头10秒冷却时间，三段能减少青龙出水和棒打狗头15秒冷却时间', icon: 'assets/wudao_icons/gaibang_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '群体输出',
      passive: WudaoPassive(name: '杀破狼', desc: '群体伤害技能的伤害增加10%，擒龙式降低的命中效果翻倍', icon: 'assets/wudao_icons/gaibang_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '蟠龙击·神威', effect: '蟠龙击增加的外功攻击额外增加100%', icon: 'assets/wudao_icons/gaibang_s1_l0_n0.webp'), WudaoNode(name: '千里烟瘴', effect: '千里横行额外增加毒攻击750点', icon: 'assets/wudao_icons/gaibang_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '速战速决', effect: '天下无狗的冷却时间减少100秒', icon: 'assets/wudao_icons/gaibang_s1_l1_n0.webp'), WudaoNode(name: '风掠广陌', effect: '天下无狗的范围修改为10米', icon: 'assets/wudao_icons/gaibang_s1_l1_n1.webp'), WudaoNode(name: '千里疾驰', effect: '千里横行的冷却时间减少25秒', icon: 'assets/wudao_icons/gaibang_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '龙行乾坤', effect: '蟠龙击会心一击时有30%概率减少横扫乾坤2秒冷却', icon: 'assets/wudao_icons/gaibang_s1_l2_n0.webp'), WudaoNode(name: '迭步蓄势', effect: '每次闪避攻击增加25点怒气', icon: 'assets/wudao_icons/gaibang_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '断肠天涯', effect: '横扫乾坤额外增加毒攻500点', icon: 'assets/wudao_icons/gaibang_s1_l3_n0.webp'), WudaoNode(name: '乾坤覆', effect: '横扫乾坤的伤害提高为115%，目标修改为8个', icon: 'assets/wudao_icons/gaibang_s1_l3_n1.webp'), WudaoNode(name: '潜龙入海', effect: '龙战于野修改为增加自身25%闪避率，持续15秒或者闪避15次失效', icon: 'assets/wudao_icons/gaibang_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'mingjiao': [
    WudaoSchool(
      name: '单点输出',
      passive: WudaoPassive(name: '不死不休', desc: '选择流派后获得主动技能：不死不休，可对1个敌对目标使用，自身在攻击此目标时命中率增加7%，持续30秒，冷却时间30秒', icon: 'assets/wudao_icons/mingjiao_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '摧心掌:神威', effect: '催心掌增加的外功攻击额外增加100%', icon: 'assets/wudao_icons/mingjiao_s0_l0_n0.webp'), WudaoNode(name: '烽燧相望', effect: '血战八方的冷却时间减少10秒', icon: 'assets/wudao_icons/mingjiao_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '天罗地网', effect: '炎龙无双的命中率增加10%', icon: 'assets/wudao_icons/mingjiao_s0_l1_n0.webp'), WudaoNode(name: '引火成缚', effect: '火烧赤壁的命中率增加10%', icon: 'assets/wudao_icons/mingjiao_s0_l1_n1.webp'), WudaoNode(name: '一炬万顷', effect: '地狱火修改为群体攻击，对自身周围5米范围内最多5个目标造成1次附带火属性750点的伤害', icon: 'assets/wudao_icons/mingjiao_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '撼岳龙腾', effect: '催心掌命中目标时，有10%概率减少炎龙无双2秒冷却时间', icon: 'assets/wudao_icons/mingjiao_s0_l2_n0.webp'), WudaoNode(name: '步步为营', effect: '催心掌未命中目标时，触发状态：稳健，命中率增加3%，持续5秒', icon: 'assets/wudao_icons/mingjiao_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '东风已至', effect: '火烧赤壁的伤害提高25%', icon: 'assets/wudao_icons/mingjiao_s0_l3_n0.webp'), WudaoNode(name: '焚天炽地', effect: '炎龙无双伤害提高20%', icon: 'assets/wudao_icons/mingjiao_s0_l3_n1.webp'), WudaoNode(name: '火浪滔天', effect: '怒火连斩开启时，前15次攻击每次命中目标都有100%的概率减少怒火连斩2秒冷却时间', icon: 'assets/wudao_icons/mingjiao_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '暴烈拼血',
      passive: WudaoPassive(name: '怒焰焚世', desc: '选择此流派后，受到伤害时，当自身血量在51%-80%时，获得怒焰一重，造成的伤害增加5%，会心一击率增加1%；当前血量在20%-50%时，获得怒焰二重，造成的伤害增加10%，会心一击率增加3%；当前血量低于20%时，获得怒焰三重，造成的伤害增加15%，会心一击率增加5%', icon: 'assets/wudao_icons/mingjiao_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '摧心掌:神威', effect: '催心掌增加的外功攻击额外增加100%', icon: 'assets/wudao_icons/mingjiao_s1_l0_n0.webp'), WudaoNode(name: '明光悬', effect: '炎龙无双的冷却时间减少5秒', icon: 'assets/wudao_icons/mingjiao_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '骤雨颓垣', effect: '水淹七军触发虚弱状态的概率增加25%', icon: 'assets/wudao_icons/mingjiao_s1_l1_n0.webp'), WudaoNode(name: '化坎入离', effect: '水淹七军增加的冰攻击100%转化为火攻击', icon: 'assets/wudao_icons/mingjiao_s1_l1_n1.webp'), WudaoNode(name: '雷霆之怒', effect: '怒发冲冠增加的外功攻击修改为原本的200%，同时额外降低同等内外功防御', icon: 'assets/wudao_icons/mingjiao_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '烛芯烬', effect: '炎龙无双会心一击时有50%概率减少怒火连斩10s冷却时间', icon: 'assets/wudao_icons/mingjiao_s1_l2_n0.webp'), WudaoNode(name: '慨当以慷', effect: '催心掌会心一击时额外获得25点怒气', icon: 'assets/wudao_icons/mingjiao_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '天地为炉', effect: '怒火连斩的15次伤害修改为10次伤害，修改后的第1次伤害即为原本的第6次伤害，第10次伤害即为原本的第15次伤害，同时这10次伤害增加会心一击率10%', icon: 'assets/wudao_icons/mingjiao_s1_l3_n0.webp'), WudaoNode(name: '付之一烬', effect: '怒火连斩开启后，消耗自身20%血量，同时增加20%会心一击率和15%免控率。但是期间无法获得任何血量回复', icon: 'assets/wudao_icons/mingjiao_s1_l3_n1.webp'), WudaoNode(name: '乘势追击', effect: '无中生有额外提升自身30%内外功攻击', icon: 'assets/wudao_icons/mingjiao_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'shaolin': [
    WudaoSchool(
      name: '攻防兼备',
      passive: WudaoPassive(name: '禅武印', desc: '伏虎拳命中目标后触发状态，在接下来的6秒内，用门派伤害技能对目标的第3次伤害附带自身血上限2%的直接伤害。', icon: 'assets/wudao_icons/shaolin_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '伏虎拳·神威', effect: '伏虎拳增加的外攻击额外增加100%', icon: 'assets/wudao_icons/shaolin_s0_l0_n0.webp'), WudaoNode(name: '佛灯压顶', effect: '金刚伏魔圈额外增加玄攻击750点', icon: 'assets/wudao_icons/shaolin_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '摩诃碎甲', effect: '摩诃无量触发破绽时，额外降低目标的10%的外功防御', icon: 'assets/wudao_icons/shaolin_s0_l1_n0.webp'), WudaoNode(name: '行道迟迟', effect: '一拍两散触发的僵硬使目标的速度额外降低25%', icon: 'assets/wudao_icons/shaolin_s0_l1_n1.webp'), WudaoNode(name: '禅力裂地', effect: '大力金刚掌额外增加玄攻击750点', icon: 'assets/wudao_icons/shaolin_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '长虹凌日', effect: '气贯长虹增加的会心额外增加10点', icon: 'assets/wudao_icons/shaolin_s0_l2_n0.webp'), WudaoNode(name: '伏虎迎佛', effect: '伏虎拳命中目标时有10%概率减少大力金刚掌2秒冷却', icon: 'assets/wudao_icons/shaolin_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '不动如山', effect: '调虎离山的目标对自身造成的伤害降低15%', icon: 'assets/wudao_icons/shaolin_s0_l3_n0.webp'), WudaoNode(name: '舍身除魔', effect: '慈航普度给自己释放时，自身伤害增加10%', icon: 'assets/wudao_icons/shaolin_s0_l3_n1.webp'), WudaoNode(name: '佛手开天', effect: '大力金刚掌造成的伤害提高20%', icon: 'assets/wudao_icons/shaolin_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '团战坦克',
      passive: WudaoPassive(name: '法身印', desc: '在5秒内受到玩家的伤害而损失的总血量超过30%时，触发获得一个自身5%血上限的盾，同时清除所有的负面状态，10秒内仅可触发1次', icon: 'assets/wudao_icons/shaolin_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '伏虎拳·神威', effect: '伏虎拳增加的外攻击额外增加100%', icon: 'assets/wudao_icons/shaolin_s1_l0_n0.webp'), WudaoNode(name: '佛法无边', effect: '金刚伏魔圈的范围增加5米', icon: 'assets/wudao_icons/shaolin_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '无垢佛身', effect: '易筋锻骨冷却时间减少50秒', icon: 'assets/wudao_icons/shaolin_s1_l1_n0.webp'), WudaoNode(name: '筋骨道基', effect: '易筋锻骨额外增加5%的血上限和恢复5%的血量', icon: 'assets/wudao_icons/shaolin_s1_l1_n1.webp'), WudaoNode(name: '梵音镇神', effect: '狮子吼修改为：15秒冷却。群体攻击，令自身周围7米范围内，最多5个目标散功0.5秒', icon: 'assets/wudao_icons/shaolin_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '魔心种佛', effect: '每次受到攻击有10%概率减少百无禁忌2秒冷却', icon: 'assets/wudao_icons/shaolin_s1_l2_n0.webp'), WudaoNode(name: '金刚怒目', effect: '每次受到攻击额外增加5点怒气', icon: 'assets/wudao_icons/shaolin_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '诸佛无相', effect: '百无禁忌的冷却时间减少10秒', icon: 'assets/wudao_icons/shaolin_s1_l3_n0.webp'), WudaoNode(name: '佛心行持', effect: '百无禁忌的持续时间增加5秒', icon: 'assets/wudao_icons/shaolin_s1_l3_n1.webp'), WudaoNode(name: '佛缘业火', effect: '礼敬如来增加反射伤害5%', icon: 'assets/wudao_icons/shaolin_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'tianlong': [
    WudaoSchool(
      name: '稳定输出',
      passive: WudaoPassive(name: '化乾转坤', desc: '在释放百步穿杨时，额外获得1个状态：化乾转坤，增加自身5%会心一击率，同时自身受到的所有伤害增加3%，持续20秒', icon: 'assets/wudao_icons/tianlong_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '正阳手·神威', effect: '正阳手增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/tianlong_s0_l0_n0.webp'), WudaoNode(name: '啸惊天地', effect: '金玉满堂增加的会心额外增加150%', icon: 'assets/wudao_icons/tianlong_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '千山灭', effect: '一阳指增加的额外伤害提高35%', icon: 'assets/wudao_icons/tianlong_s0_l1_n0.webp'), WudaoNode(name: '飞光不附', effect: '一阳指命中目标时，有25%概率降低目标30%的速度，持续10秒', icon: 'assets/wudao_icons/tianlong_s0_l1_n1.webp'), WudaoNode(name: '怒震列缺', effect: '少泽剑增加的额外伤害提升35%', icon: 'assets/wudao_icons/tianlong_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '烛龙衔光', effect: '一阳指命中目标时有10%概率清除一阳指的冷却时间', icon: 'assets/wudao_icons/tianlong_s0_l2_n0.webp'), WudaoNode(name: '恨断青山', effect: '商阳剑命中目标时有50%概率增加50点怒气', icon: 'assets/wudao_icons/tianlong_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '死生无门', effect: '攻击被八门金锁封印的目标时，一阳指的伤害提高20%', icon: 'assets/wudao_icons/tianlong_s0_l3_n0.webp'), WudaoNode(name: '风云从龙', effect: '攻击有商阳剑异常状态的目标时，少泽剑的伤害提升40%', icon: 'assets/wudao_icons/tianlong_s0_l3_n1.webp'), WudaoNode(name: '太白入月', effect: '攻击有商阳剑异常状态的目标时，会心率提升3%', icon: 'assets/wudao_icons/tianlong_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '四属堆叠',
      passive: WudaoPassive(name: '谒天应行', desc: '选择该流派后，将获得状态谒天应行，使用正阳手攻击目标时，有10%的概率触发下列四种状态中的一种：扣冰，对比自身和目标冰攻，高于对方则释放，给目标一个减速55%，持续10秒的状态，状态结束时，会再给目标1个0.5秒的麻痹效果；业火，对比自身和目标火攻，高于对方则释放，给自身一个四属性减抗下限提高3点的状态，持续5秒；玄虚，对比自身和目标玄攻，高于对方则释放，给目标1个1秒的眩晕；邪毒，对比自身和目标毒攻，高于对方则释放，使目标中毒，每秒掉自身20%毒攻的血量，持续10秒', icon: 'assets/wudao_icons/tianlong_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '正阳手·神威', effect: '正阳手增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/tianlong_s1_l0_n0.webp'), WudaoNode(name: '恩拂九重', effect: '以逸待劳增加的命中额外增加30%', icon: 'assets/wudao_icons/tianlong_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '万壑深', effect: '欲擒故纵增加的内外功攻击额外增加40%', icon: 'assets/wudao_icons/tianlong_s1_l1_n0.webp'), WudaoNode(name: '蹈死难顾', effect: '欲擒故纵触发的破绽效果，使目标的内外功攻击降低额外增加25%', icon: 'assets/wudao_icons/tianlong_s1_l1_n1.webp'), WudaoNode(name: '缘门始开', effect: '少泽剑使目标内外功攻击和防御额外降低10%', icon: 'assets/wudao_icons/tianlong_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '不问修罗', effect: '欲擒故纵命中目标时有50%概率减少中冲剑5秒冷却', icon: 'assets/wudao_icons/tianlong_s1_l2_n0.webp'), WudaoNode(name: '择风化雨', effect: '正阳手命中目标时有25%概率减少静影沉璧2秒冷却', icon: 'assets/wudao_icons/tianlong_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '众生如来', effect: '中冲剑的降低抗性额外增加15点', icon: 'assets/wudao_icons/tianlong_s1_l3_n0.webp'), WudaoNode(name: '万鬼难渡', effect: '雪拥蓝关触发封穴的概率增加5%', icon: 'assets/wudao_icons/tianlong_s1_l3_n1.webp'), WudaoNode(name: '风月同悲', effect: '静影沉璧会额外造成减少的气的50%的血量伤害', icon: 'assets/wudao_icons/tianlong_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'tianshan': [
    WudaoSchool(
      name: '持续输出',
      passive: WudaoPassive(name: '寒芒乍现', desc: '雁南飞命中目标，有15%的概率获得状态：寒芒乍现，增加3%命中率，增强凤舞九天15%伤害，状态持续3秒。雁南飞命中目标时可刷新此状态', icon: 'assets/wudao_icons/tianshan_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '雁南飞·神威', effect: '雁南飞的外功攻击额外增加100%', icon: 'assets/wudao_icons/tianshan_s0_l0_n0.webp'), WudaoNode(name: '冰封雪舞', effect: '雪花六出触发时不再增加会心，修改为增加命中1000点', icon: 'assets/wudao_icons/tianshan_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '箫韶引凤', effect: '凤舞九天的冷却时间减少10秒', icon: 'assets/wudao_icons/tianshan_s0_l1_n0.webp'), WudaoNode(name: '生死一念', effect: '凤舞九天的会心率增加5%', icon: 'assets/wudao_icons/tianshan_s0_l1_n1.webp'), WudaoNode(name: '万翎千机', effect: '凤舞九天的命中率增加10%', icon: 'assets/wudao_icons/tianshan_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '鸿雁来宾', effect: '雁南飞命中目标时有10%概率减少鹰击长空2秒冷却', icon: 'assets/wudao_icons/tianshan_s0_l2_n0.webp'), WudaoNode(name: '凤回首', effect: '凤舞九天命中目标有10%概率清除凤舞九天的冷却时间', icon: 'assets/wudao_icons/tianshan_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '孤鹰戾天', effect: '鹰击长空增加的冰攻击额外增加500点', icon: 'assets/wudao_icons/tianshan_s0_l3_n0.webp'), WudaoNode(name: '无边落木', effect: '移花接木增加的伤害额外增加250点', icon: 'assets/wudao_icons/tianshan_s0_l3_n1.webp'), WudaoNode(name: '霜冷九州', effect: '凤舞九天增加的冰攻击额外增加750点', icon: 'assets/wudao_icons/tianshan_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '隐匿单杀',
      passive: WudaoPassive(name: '匿影绝杀', desc: '隐身后获得状态：匿影绝杀，在对玩家目标的第一个单体伤害技能增加35%伤害，同时获得3秒会心率加8%的状态', icon: 'assets/wudao_icons/tianshan_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '雁南飞·神威', effect: '雁南飞的外功攻击额外增加100%', icon: 'assets/wudao_icons/tianshan_s1_l0_n0.webp'), WudaoNode(name: '杀意袭', effect: '雪花六出增加的会心额外增加10点', icon: 'assets/wudao_icons/tianshan_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '寒梅寂', effect: '梅花三弄触发僵硬的概率额外增加25%', icon: 'assets/wudao_icons/tianshan_s1_l1_n0.webp'), WudaoNode(name: '杀生予夺', effect: '攻击有铁锁横江状态的目标时，会心率增加4%', icon: 'assets/wudao_icons/tianshan_s1_l1_n1.webp'), WudaoNode(name: '暮雪将倾', effect: '雪花六出的冷却时间减少5秒', icon: 'assets/wudao_icons/tianshan_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '雁寄梅花', effect: '雁南飞会心一击时有20%概率减少寒梅怒放2秒冷却', icon: 'assets/wudao_icons/tianshan_s1_l2_n0.webp'), WudaoNode(name: '悲雁鸣', effect: '雁南飞会心一击时额外获得25点怒气', icon: 'assets/wudao_icons/tianshan_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '长夜无昼', effect: '寒梅怒放的伤害(包括触发的额外攻击)提高到125%', icon: 'assets/wudao_icons/tianshan_s1_l3_n0.webp'), WudaoNode(name: '梅开二度', effect: '寒梅怒放发动一次额外攻击的几率提高为55%', icon: 'assets/wudao_icons/tianshan_s1_l3_n1.webp'), WudaoNode(name: '一曲成殇', effect: '阳关三叠修改为增加会心率15%，持续13秒或会心一击5次失效', icon: 'assets/wudao_icons/tianshan_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'wudang': [
    WudaoSchool(
      name: '单体输出',
      passive: WudaoPassive(name: '海纳川行诀', desc: '流星赶月将血伤害转化为气伤害时，只消耗65%的气。挑帘式攻击目标增加的气翻倍', icon: 'assets/wudao_icons/wudang_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '八卦掌·神威', effect: '八卦掌增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/wudang_s0_l0_n0.webp'), WudaoNode(name: '万辰莹辉', effect: '天罡北斗阵额外增加10%气上限%', icon: 'assets/wudao_icons/wudang_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '踏碎星河', effect: '天马飞瀑造成的伤害增加30%', icon: 'assets/wudao_icons/wudang_s0_l1_n0.webp'), WudaoNode(name: '酣然魂逝', effect: '天马飞瀑对有揽雀尾目标造成的伤害增加50%', icon: 'assets/wudao_icons/wudang_s0_l1_n1.webp'), WudaoNode(name: '澹兮岚萦', effect: '仙风道骨的持续时间增加10秒', icon: 'assets/wudao_icons/wudang_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '八卦衍', effect: '八卦掌命中目标时有15%概率减少两仪剑2秒冷却时间', icon: 'assets/wudao_icons/wudang_s0_l2_n0.webp'), WudaoNode(name: '紫气东来', effect: '挑帘式触发增加气的概率增加10%', icon: 'assets/wudao_icons/wudang_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '一剑万钧', effect: '两仪剑造成的伤害增加35%', icon: 'assets/wudao_icons/wudang_s0_l3_n0.webp'), WudaoNode(name: '纳灵凝丹', effect: '两仪剑每秒对目标造成伤害时，会额外吸收目标当次伤害量10%的血和气给自身', icon: 'assets/wudao_icons/wudang_s0_l3_n1.webp'), WudaoNode(name: '太初将至', effect: '如封似闭的冷却时间减少10秒', icon: 'assets/wudao_icons/wudang_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '移动输出',
      passive: WudaoPassive(name: '七步登云庭', desc: '释放群体技能后，获得状态：踏岳，5秒内移动距离超过7米则获得1个持续10秒的状态：携霆，使单体伤害技能造成的伤害增加5%，会心一击率增加1%；群体伤害技能伤害增加10%，会心一击率增加2%。', icon: 'assets/wudao_icons/wudang_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '八卦掌·神威', effect: '八卦掌增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/wudang_s1_l0_n0.webp'), WudaoNode(name: '清风快哉', effect: '真武七截阵的冷却时间降低10秒', icon: 'assets/wudao_icons/wudang_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '虚步青云', effect: '梯云纵的冷却时间减少20秒', icon: 'assets/wudao_icons/wudang_s1_l1_n0.webp'), WudaoNode(name: '裁风绊月', effect: '三环套月的减速效果提高为65%', icon: 'assets/wudao_icons/wudang_s1_l1_n1.webp'), WudaoNode(name: '斗转星驰', effect: '七星聚首的冷却时间降低5秒', icon: 'assets/wudao_icons/wudang_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '爻动星移', effect: '八卦掌会心一击时有30%概率减少七星聚首2秒冷却', icon: 'assets/wudao_icons/wudang_s1_l2_n0.webp'), WudaoNode(name: '星涛怒浪', effect: '七星聚首击中每个目标后都有25%概率额外获得20点怒气', icon: 'assets/wudao_icons/wudang_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '天钺横空', effect: '七星聚首的伤害增加15%', icon: 'assets/wudao_icons/wudang_s1_l3_n0.webp'), WudaoNode(name: '罡风袭月', effect: '三环套月释放后，自身获得一个持续10秒，加速20%的状态', icon: 'assets/wudao_icons/wudang_s1_l3_n1.webp'), WudaoNode(name: '星隐鹤啼', effect: '白鹤亮翅状态下，攻击目标获得的怒气值增加10点', icon: 'assets/wudao_icons/wudang_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'xiaoyao': [
    WudaoSchool(
      name: '飘逸输出',
      passive: WudaoPassive(name: '飞星晔夜', desc: '使用落英剑命中目标时，有10%概率触发一个10秒的状态，溪山行旅的命中率增加5%；使用凌波微步后，100%触发一个10秒的状态，聘风，溪山行旅命中率增加12%。', icon: 'assets/wudao_icons/xiaoyao_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '落英剑·神威', effect: '落英剑增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/xiaoyao_s0_l0_n0.webp'), WudaoNode(name: '霁月行空', effect: '云体风身增加的会心攻击提高为200%', icon: 'assets/wudao_icons/xiaoyao_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '一指透春寒', effect: '弹指神功对带有溪山行旅的目标使用时，额外增加3%会心一击率', icon: 'assets/wudao_icons/xiaoyao_s0_l1_n0.webp'), WudaoNode(name: '凌霄揽月', effect: '鲲跃北溟将附带普攻伤害，并吸收伤害的25%化为己用', icon: 'assets/wudao_icons/xiaoyao_s0_l1_n1.webp'), WudaoNode(name: '旋花穿云', effect: '溪山行旅的会心一击率增加2.5%', icon: 'assets/wudao_icons/xiaoyao_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '时移如梭', effect: '弹指神功命中目标时有20%概率清除溪山行旅冷却', icon: 'assets/wudao_icons/xiaoyao_s0_l2_n0.webp'), WudaoNode(name: '绘洗晴岚', effect: '溪山行旅命中目标时有10%概率清除弹指神功冷却', icon: 'assets/wudao_icons/xiaoyao_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '畅淋漓', effect: '溪山行旅造成的伤害提高25%', icon: 'assets/wudao_icons/xiaoyao_s0_l3_n0.webp'), WudaoNode(name: '踏浪濯心', effect: '溪山行旅对带有带有溪山行旅的目标使用时，额外增加5%命中率', icon: 'assets/wudao_icons/xiaoyao_s0_l3_n1.webp'), WudaoNode(name: '穿林打叶', effect: '弹指神功的命中率增加5%', icon: 'assets/wudao_icons/xiaoyao_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '陷阱大师',
      passive: WudaoPassive(name: '欺烟困雨', desc: '使用落英剑命中目标时，有10%概率触发一个10秒的状态，在此状态下，释放的桃花阵伤害翻倍；释放的八阵图作用范围从4米修改为7米；释放的诛仙阵作用范围从4米修改为7米；定海神针额外给目标1个减速30%，持续3秒的状态；步步生花额外造成0.2秒的散功效果。画地为牢命中目标必定触发陷阱精通效果', icon: 'assets/wudao_icons/xiaoyao_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '落英剑·神威', effect: '落英剑增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/xiaoyao_s1_l0_n0.webp'), WudaoNode(name: '骨重识寒', effect: '桃花阵的伤害增加25%', icon: 'assets/wudao_icons/xiaoyao_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '碎尘泥', effect: '定海神针的每次伤害增加50%', icon: 'assets/wudao_icons/xiaoyao_s1_l1_n0.webp'), WudaoNode(name: '罔象促梦', effect: '定海神针的冷却时间减少10秒', icon: 'assets/wudao_icons/xiaoyao_s1_l1_n1.webp'), WudaoNode(name: '烛花催夜', effect: '画地为牢的冷却时间减少10秒', icon: 'assets/wudao_icons/xiaoyao_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '残春待晓', effect: '步步生花释放时，有75%概率减少步步生花10秒冷却', icon: 'assets/wudao_icons/xiaoyao_s1_l2_n0.webp'), WudaoNode(name: '怨清商', effect: '步步生花的陷阱造成伤害时，有30%概率增加20点怒气', icon: 'assets/wudao_icons/xiaoyao_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '浪流风逐', effect: '开启步步生花时，自身移动速度增加10%', icon: 'assets/wudao_icons/xiaoyao_s1_l3_n0.webp'), WudaoNode(name: '烟霏殁', effect: '步步生花的陷阱伤害提高50%', icon: 'assets/wudao_icons/xiaoyao_s1_l3_n1.webp'), WudaoNode(name: '蔽日吞天', effect: '惊涛骇浪额外增加一个持续1.5秒的定身状态', icon: 'assets/wudao_icons/xiaoyao_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'xingxiu': [
    WudaoSchool(
      name: '单体炮台',
      passive: WudaoPassive(name: '冥星照顶', desc: '选择流派后，获得主动技能：冥星照顶，使用后，在当前坐标站定10秒后，每过2秒，增加1%伤害，最高10%，移动消失。技能无CD', icon: 'assets/wudao_icons/xingxiu_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '蓝砂手·神威', effect: '蓝砂手增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/xingxiu_s0_l0_n0.webp'), WudaoNode(name: '幽冥急袭', effect: '幽冥神掌的运气时间减少50%', icon: 'assets/wudao_icons/xingxiu_s0_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '冰寒绝息', effect: '冰蚕毒掌造成的伤害提高25%', icon: 'assets/wudao_icons/xingxiu_s0_l1_n0.webp'), WudaoNode(name: '掌势潮涌', effect: '幽冥神掌的冷却时间减少5秒', icon: 'assets/wudao_icons/xingxiu_s0_l1_n1.webp'), WudaoNode(name: '幽冥寂灭', effect: '幽冥神掌造成的伤害提高40%', icon: 'assets/wudao_icons/xingxiu_s0_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '掌迫生机', effect: '幽冥神掌命中目标时有50%概率减少一日丧命散10秒冷却', icon: 'assets/wudao_icons/xingxiu_s0_l2_n0.webp'), WudaoNode(name: '辣手戾心', effect: '蓝砂手命中目标时有10%概率增加30点怒气', icon: 'assets/wudao_icons/xingxiu_s0_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '阎王来帖', effect: '一日丧命散对当前目标造成的伤害提高15%', icon: 'assets/wudao_icons/xingxiu_s0_l3_n0.webp'), WudaoNode(name: '天损有余', effect: '天地同寿对当前血量超过50%的目标造成的伤害提高10%', icon: 'assets/wudao_icons/xingxiu_s0_l3_n1.webp'), WudaoNode(name: '地杀不足', effect: '天地同寿对当前血量低于50%的目标造成的伤害提高10%', icon: 'assets/wudao_icons/xingxiu_s0_l3_n2.webp')]),
      ],
    ),
    WudaoSchool(
      name: '状态控制',
      passive: WudaoPassive(name: '巫蛊降厄', desc: '选择该流派后，将获得状态：巫蛊降厄，使用蓝砂手命中目标时，有3%概率会使含笑半步颠清除冷却，有3%概率会使毒蟾功清除冷却。', icon: 'assets/wudao_icons/xingxiu_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '蓝砂手·神威', effect: '蓝砂手增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/xingxiu_s1_l0_n0.webp'), WudaoNode(name: '惜金蟾蜍', effect: '毒蟾功的运气时间减少50%', icon: 'assets/wudao_icons/xingxiu_s1_l0_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '毒厄夺命', effect: '蝎尾针在造成僵硬效果时，会附带自身伤害及毒攻击加200点的伤害', icon: 'assets/wudao_icons/xingxiu_s1_l1_n0.webp'), WudaoNode(name: '余罪缠身', effect: '蝎尾针的减速效果修改为65%', icon: 'assets/wudao_icons/xingxiu_s1_l1_n1.webp'), WudaoNode(name: '颠倒阴阳', effect: '指鹿为马打怒吸怒效果提升30%', icon: 'assets/wudao_icons/xingxiu_s1_l1_n2.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '蛇毒浸体', effect: '青蛇毒掌命中目标时有75%概率减少一日丧命散10秒冷却', icon: 'assets/wudao_icons/xingxiu_s1_l2_n0.webp'), WudaoNode(name: '天怒地愤', effect: '天地同寿触发两次额外攻击时，额外增加150点怒气', icon: 'assets/wudao_icons/xingxiu_s1_l2_n1.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '长恨绵绵', effect: '化骨绵掌的冷却时间减少100秒', icon: 'assets/wudao_icons/xingxiu_s1_l3_n0.webp'), WudaoNode(name: '噬血吸髓', effect: '笑里藏刀修改为：持续发功8秒，每秒造成一次普攻伤害，并将35%的伤害吸收为自己的血', icon: 'assets/wudao_icons/xingxiu_s1_l3_n1.webp'), WudaoNode(name: '咒昭重厄', effect: '天地同寿触发两次额外攻击的几率增加10%', icon: 'assets/wudao_icons/xingxiu_s1_l3_n2.webp')]),
      ],
    ),
  ],
  'erengu': [
    WudaoSchool(
      name: '溯魂',
      passive: WudaoPassive(name: '天行有常', desc: '拘魂·天、拘魂·地、拘魂·命的冷却时间降低为5秒', icon: 'assets/wudao_icons/erengu_s0_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '剜心镰·神威', effect: '剜心镰增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/erengu_s0_l0_n0.webp'), WudaoNode(name: '恶瘴盈身', effect: '银钩走蝎增加的毒攻击额外增加20%', icon: 'assets/wudao_icons/erengu_s0_l0_n1.webp'), WudaoNode(name: '百无一失', effect: '拘魂·地的命中率增加10%', icon: 'assets/wudao_icons/erengu_s0_l0_n2.webp'), WudaoNode(name: '万念归尘', effect: '拘魂·地造成的伤害提高15%', icon: 'assets/wudao_icons/erengu_s0_l0_n3.webp'), WudaoNode(name: '百战不殆', effect: '万恶同赦增加的血上限额外增加20%', icon: 'assets/wudao_icons/erengu_s0_l0_n4.webp'), WudaoNode(name: '心灰意冷', effect: '剜心镰命中目标时有10%概率减少剔魂削骨2秒冷却', icon: 'assets/wudao_icons/erengu_s0_l0_n5.webp'), WudaoNode(name: '魂销魄散', effect: '摧魂定魄造成的伤害提高10%', icon: 'assets/wudao_icons/erengu_s0_l0_n6.webp'), WudaoNode(name: '无人不冤', effect: '拘魂·天使目标获得的丧魂·天状态，对恶人谷造成的降低伤害提高到15%', icon: 'assets/wudao_icons/erengu_s0_l0_n7.webp'), WudaoNode(name: '红尘应怜', effect: '拘魂·地使自身获得的拘魂·地状态，降低伤害提高到10%', icon: 'assets/wudao_icons/erengu_s0_l0_n8.webp'), WudaoNode(name: '药石无效', effect: '拘魂·命使目标获得的丧魂·命状态，获得的降低治疗效果提高到85%', icon: 'assets/wudao_icons/erengu_s0_l0_n9.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '剜心镰·滞脉', effect: '剜心镰攻击目标时，有20%概率无视目标30%的内功防御', icon: 'assets/wudao_icons/erengu_s0_l1_n0.webp'), WudaoNode(name: '剜心镰·攻心', effect: '剜心镰对目标造成的内功攻击伤害增加5%', icon: 'assets/wudao_icons/erengu_s0_l1_n1.webp'), WudaoNode(name: '云扼寒山', effect: '拘魂·天命中目标后有10%概率使目标封印1.5秒', icon: 'assets/wudao_icons/erengu_s0_l1_n2.webp'), WudaoNode(name: '乘虚而入', effect: '拘魂·天攻击有剔魂削骨虚弱状态的目标，增加10%命中率', icon: 'assets/wudao_icons/erengu_s0_l1_n3.webp'), WudaoNode(name: '气若游丝', effect: '魂削骨触发虚弱的概率增加10%', icon: 'assets/wudao_icons/erengu_s0_l1_n4.webp'), WudaoNode(name: '冷镰缚影', effect: '剜心镰对目标造成伤害时，有5%概率使目标减速45%，持续3秒', icon: 'assets/wudao_icons/erengu_s0_l1_n5.webp'), WudaoNode(name: '歃血砺刃', effect: '剜心镰命中目标时有10%概率减少炉上青烟2秒冷却', icon: 'assets/wudao_icons/erengu_s0_l1_n6.webp'), WudaoNode(name: '唯我自在', effect: '主动技，使自身会心一击伤害提高20%，持续8秒。冷却时间150秒', icon: 'assets/wudao_icons/erengu_s0_l1_n7.webp'), WudaoNode(name: '凝光照雪', effect: '主动技，使自身会心提高10%，持续8秒。冷却时间150秒', icon: 'assets/wudao_icons/erengu_s0_l1_n8.webp'), WudaoNode(name: '气定神闲', effect: '主动技，自身获得1个持续5秒的状态，状态持续期间内有30%概率免疫伤害，最多免疫2次伤害，冷却时间130秒', icon: 'assets/wudao_icons/erengu_s0_l1_n9.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '天魂难固', effect: '拘魂·天使目标获得的丧魂·天状态的持续时间增加0.5秒', icon: 'assets/wudao_icons/erengu_s0_l2_n0.webp'), WudaoNode(name: '地魂难固', effect: '拘魂·地使目标获得的丧魂·地状态持续时间增加0.5秒', icon: 'assets/wudao_icons/erengu_s0_l2_n1.webp'), WudaoNode(name: '毒雾弑命', effect: '炉上青烟的伤害提高15%', icon: 'assets/wudao_icons/erengu_s0_l2_n2.webp'), WudaoNode(name: '三魂再离', effect: '百倍奉还命中目标后有20%概率减少拘魂·天、拘魂·地、拘魂·命1秒冷却时间', icon: 'assets/wudao_icons/erengu_s0_l2_n3.webp'), WudaoNode(name: '天倾地覆', effect: '天地不仁的伤害提高10%', icon: 'assets/wudao_icons/erengu_s0_l2_n4.webp'), WudaoNode(name: '长恨无绝', effect: '剔魂削骨触发的虚弱状态，持续时间增加10秒', icon: 'assets/wudao_icons/erengu_s0_l2_n5.webp'), WudaoNode(name: '为我所用', effect: '拘魂·命命中玩家目标后，有25%概率立即回复自身血上限5%的血量', icon: 'assets/wudao_icons/erengu_s0_l2_n6.webp'), WudaoNode(name: '命殒业消', effect: '判指阴阳的伤害提高20%', icon: 'assets/wudao_icons/erengu_s0_l2_n7.webp'), WudaoNode(name: '有情皆孽', effect: '拘魂·地给目标的丧魂·地状态，使目标受到恶人谷的伤害提高到30%', icon: 'assets/wudao_icons/erengu_s0_l2_n8.webp'), WudaoNode(name: '魂逝灯灭', effect: '魂离魄散的伤害提高15%', icon: 'assets/wudao_icons/erengu_s0_l2_n9.webp')]),
      ],
    ),
    WudaoSchool(
      name: '判命',
      passive: WudaoPassive(name: '万劫不复', desc: '百倍奉还和魂离魄散最终的伤害提高10%', icon: 'assets/wudao_icons/erengu_s1_pd.webp'),
      layers: [
        WudaoLayer(nodes: [WudaoNode(name: '剜心镰·神威', effect: '剜心镰增加的内功攻击额外增加100%', icon: 'assets/wudao_icons/erengu_s1_l0_n0.webp'), WudaoNode(name: '世难由己', effect: '摧魂定魄的定身效果增加1秒', icon: 'assets/wudao_icons/erengu_s1_l0_n1.webp'), WudaoNode(name: '飞魂九霄', effect: '拘魂·天增加的直接攻击额外增加500点', icon: 'assets/wudao_icons/erengu_s1_l0_n2.webp'), WudaoNode(name: '动骨伤筋', effect: '剔魂削骨触发虚弱效果时，同时降低目标2000点命中', icon: 'assets/wudao_icons/erengu_s1_l0_n3.webp'), WudaoNode(name: '魂牵梦绊', effect: '摧魂定魄的冷却时间降低10秒', icon: 'assets/wudao_icons/erengu_s1_l0_n4.webp'), WudaoNode(name: '惊心怵目', effect: '剜心镰对目标造成会心一击时，有35%概率减少炉上青烟2秒冷却', icon: 'assets/wudao_icons/erengu_s1_l0_n5.webp'), WudaoNode(name: '镰风摄魄', effect: '剜心镰命中目标时有10%概率减少摧魂定魄2秒冷却', icon: 'assets/wudao_icons/erengu_s1_l0_n6.webp'), WudaoNode(name: '因果有终', effect: '百倍奉还对目标造成会心一击伤害时，此次最终伤害额外提高15%', icon: 'assets/wudao_icons/erengu_s1_l0_n7.webp'), WudaoNode(name: '一网打尽', effect: '百倍奉还击败目标时，立即清除拘魂·天、拘魂·地、拘魂·命和百倍奉还100%的冷却时间', icon: 'assets/wudao_icons/erengu_s1_l0_n8.webp'), WudaoNode(name: '斩草除根', effect: '魂离魄散每成功击败一个目标，则减少魂离魄散3秒的冷却时间', icon: 'assets/wudao_icons/erengu_s1_l0_n9.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '剜心镰·滞脉', effect: '剜心镰攻击目标时，有20%概率无视目标30%的内功防御', icon: 'assets/wudao_icons/erengu_s1_l1_n0.webp'), WudaoNode(name: '固若金汤', effect: '受到玩家的内外功伤害降低5%', icon: 'assets/wudao_icons/erengu_s1_l1_n1.webp'), WudaoNode(name: '雨锁危楼', effect: '拘魂·天会心一击后有40%概率使目标封印1.5秒', icon: 'assets/wudao_icons/erengu_s1_l1_n2.webp'), WudaoNode(name: '挥镰断魂', effect: '拘魂·地的会心一击伤害增加35%', icon: 'assets/wudao_icons/erengu_s1_l1_n3.webp'), WudaoNode(name: '夜半蛇影', effect: '炉上青烟额外增加750的毒攻击', icon: 'assets/wudao_icons/erengu_s1_l1_n4.webp'), WudaoNode(name: '噩梦缠身', effect: '剜心镰对目标造成会心一击时，有20%概率使目标减速45%，持续3秒', icon: 'assets/wudao_icons/erengu_s1_l1_n5.webp'), WudaoNode(name: '天命所归', effect: '拘魂·命对玩家目标造成会心一击时100%概率立即回复自身血上限3%的血量', icon: 'assets/wudao_icons/erengu_s1_l1_n6.webp'), WudaoNode(name: '唯我自在', effect: '主动技，使自身会心一击伤害提高20%，持续8秒。冷却时间150秒', icon: 'assets/wudao_icons/erengu_s1_l1_n7.webp'), WudaoNode(name: '凝光照雪', effect: '主动技，使自身会心提高10%，持续8秒。冷却时间150秒', icon: 'assets/wudao_icons/erengu_s1_l1_n8.webp'), WudaoNode(name: '气定神闲', effect: '主动技，自身获得1个持续5秒的状态，状态持续期间内有30%概率免疫伤害，最多免疫2次伤害，冷却时间130秒', icon: 'assets/wudao_icons/erengu_s1_l1_n9.webp')]),
        WudaoLayer(nodes: [WudaoNode(name: '有仇必报', effect: '百倍奉还的会心一击率增加3%', icon: 'assets/wudao_icons/erengu_s1_l2_n0.webp'), WudaoNode(name: '长镰葬魂', effect: '魂离魄散的会心一击率增加3%', icon: 'assets/wudao_icons/erengu_s1_l2_n1.webp'), WudaoNode(name: '魂不附体', effect: '拘魂·天的命中率提高5%', icon: 'assets/wudao_icons/erengu_s1_l2_n2.webp'), WudaoNode(name: '清浊怎辨', effect: '炉上青烟触发失明的概率提高5%', icon: 'assets/wudao_icons/erengu_s1_l2_n3.webp'), WudaoNode(name: '镰引忘川', effect: '判指阴阳的会心一击率增加3%', icon: 'assets/wudao_icons/erengu_s1_l2_n4.webp'), WudaoNode(name: '旧怨新仇', effect: '百倍奉还命中目标有30%概率减少锁魂斩2秒的冷却时间', icon: 'assets/wudao_icons/erengu_s1_l2_n5.webp'), WudaoNode(name: '残雪将融', effect: '无我三界的冷却时间减少10秒', icon: 'assets/wudao_icons/erengu_s1_l2_n6.webp'), WudaoNode(name: '嗔恨俱消', effect: '天地不仁的打怒效果额外增加100点', icon: 'assets/wudao_icons/erengu_s1_l2_n7.webp'), WudaoNode(name: '前缘再续', effect: '生死由我的持续时间增加2秒', icon: 'assets/wudao_icons/erengu_s1_l2_n8.webp'), WudaoNode(name: '斩尽杀绝', effect: '百倍奉还对血量低于20%的目标造成的伤害额外再次提高15%', icon: 'assets/wudao_icons/erengu_s1_l2_n9.webp')]),
      ],
    ),
  ],
};

/// 按门派取武道流派（未知门派返回空列表）。
List<WudaoSchool> wudaoOf(String sectKey) => kWudao[sectKey] ?? const [];

