/// 职业神器 —— 领域模型与数据（与 UI 原型 `SECT_ARTIFACTS` 一致）。
///
/// 九大门派各有专属武器，按 42 / 62 / 82 / 102 级四档；
/// 每档含名称、简介、基础属性（stats）、神兵特性（extra）与获取途径（how）。
library;

import 'package:flutter/foundation.dart';

/// 一条基础属性（如 攻击 +380）。
@immutable
class JobArtifactStat {
  const JobArtifactStat({required this.name, required this.value});

  final String name;

  /// 数值部分（如 380 / 30 / 8）。
  final String value;
}

/// 一档神器（42 / 62 / 82 / 102）。
@immutable
class JobArtifactTier {
  const JobArtifactTier({
    required this.lv,
    required this.name,
    required this.intro,
    required this.stats,
    required this.extra,
    required this.how,
  });

  final int lv;
  final String name;

  /// 神器简介。
  final String intro;

  /// 基础属性。
  final List<JobArtifactStat> stats;

  /// 神兵特性（共鸣效果）。
  final String extra;

  /// 获取途径步骤。
  final List<String> how;
}

/// 一门派的武器体系。
@immutable
class JobArtifact {
  const JobArtifact({required this.weapon, required this.tiers});

  /// 武器类型名（如 禅杖 / 长刀）。
  final String weapon;

  /// 四档神器。
  final List<JobArtifactTier> tiers;
}

/// 九大门派神器（对应原型 `SECT_ARTIFACTS`）。
const Map<String, JobArtifact> kJobArtifacts = {
  'shaolin': JobArtifact(
    weapon: '禅杖',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '韦陀伏魔杖',
        intro: '少室山精铁所铸，杖身刻韦陀像。朴实无华，却能于千军之中稳立如山。',
        stats: [
          JobArtifactStat(name: '攻击', value: '380'),
          JobArtifactStat(name: '属性攻', value: '30'),
          JobArtifactStat(name: '会心', value: '8'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '金刚降魔杖',
        intro: '融合金刚寺镇寺之铁重铸，降魔杵意灌注其中，护法之力更胜从前。',
        stats: [
          JobArtifactStat(name: '攻击', value: '760'),
          JobArtifactStat(name: '属性攻', value: '55'),
          JobArtifactStat(name: '会心', value: '14'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '般若禅音杖',
        intro: '杖动如梵音涤尘，攻守一体。相传持杖者可闻晨钟暮鼓，心境不破。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1240'),
          JobArtifactStat(name: '属性攻', value: '86'),
          JobArtifactStat(name: '会心', value: '22'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '不动明王杖',
        intro: '明王怒目，杖镇八方。少林千年武学之魂所聚，一杖落下如山岳倾覆。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1850'),
          JobArtifactStat(name: '属性攻', value: '128'),
          JobArtifactStat(name: '会心', value: '32'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'mingjiao': JobArtifact(
    weapon: '长刀',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '烈焰斩马刀',
        intro: '光明顶火山铁淬炼，刀锋暗藏火纹。出手如烈焰扑面，势不可挡。',
        stats: [
          JobArtifactStat(name: '攻击', value: '400'),
          JobArtifactStat(name: '属性攻', value: '30'),
          JobArtifactStat(name: '会心', value: '9'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '焚天裂地刀',
        intro: '以圣火令残片熔铸，刀气所过之处如焚天之势，裂地成壑。',
        stats: [
          JobArtifactStat(name: '攻击', value: '790'),
          JobArtifactStat(name: '属性攻', value: '55'),
          JobArtifactStat(name: '会心', value: '15'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '炽阳曜日刀',
        intro: '刀出如炽阳当空，圣火熊熊。明教弟子以持此刀为荣。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1290'),
          JobArtifactStat(name: '属性攻', value: '86'),
          JobArtifactStat(name: '会心', value: '23'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '焚尽八荒刀',
        intro: '圣火终极形态，一刀出而八荒焚。燃烧自身气血换取毁灭性爆发。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1920'),
          JobArtifactStat(name: '属性攻', value: '128'),
          JobArtifactStat(name: '会心', value: '33'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'gaibang': JobArtifact(
    weapon: '玉棒',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '打狗伏虎棒',
        intro: '百代丐帮弟子传棒之所聚，棒法刚猛，缠斗不歇。',
        stats: [
          JobArtifactStat(name: '攻击', value: '380'),
          JobArtifactStat(name: '属性攻', value: '30'),
          JobArtifactStat(name: '会心', value: '8'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '降龙镇岳棒',
        intro: '棒身嵌十八掌精要铜环，一棒镇岳，连绵不绝。',
        stats: [
          JobArtifactStat(name: '攻击', value: '760'),
          JobArtifactStat(name: '属性攻', value: '55'),
          JobArtifactStat(name: '会心', value: '14'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '醉饮江湖棒',
        intro: '棒中藏酒囊，醉意越浓棒势越烈，江湖人称「醉棒无双」。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1240'),
          JobArtifactStat(name: '属性攻', value: '86'),
          JobArtifactStat(name: '会心', value: '22'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '天罡镇世棒',
        intro: '聚天下丐帮气运所铸，棒出如天罡临世，镇世安邦。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1850'),
          JobArtifactStat(name: '属性攻', value: '128'),
          JobArtifactStat(name: '会心', value: '32'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'tianshan': JobArtifact(
    weapon: '双环',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '寒梅映雪环',
        intro: '缥缈峰万年寒铁所制，环影如寒梅映雪，杀机暗藏。',
        stats: [
          JobArtifactStat(name: '攻击', value: '390'),
          JobArtifactStat(name: '属性攻', value: '30'),
          JobArtifactStat(name: '会心', value: '10'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '冰魄凝霜环',
        intro: '冰魄之力凝于环身，出手无声，环至霜落，取敌于无形。',
        stats: [
          JobArtifactStat(name: '攻击', value: '775'),
          JobArtifactStat(name: '属性攻', value: '55'),
          JobArtifactStat(name: '会心', value: '16'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '朔风碎玉环',
        intro: '环舞如朔风卷雪，碎玉之音便是夺命之音。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1265'),
          JobArtifactStat(name: '属性攻', value: '86'),
          JobArtifactStat(name: '会心', value: '24'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '广寒霜天环',
        intro: '广寒霜降，环锁天地。天山刺客的终极杀器，一环出而霜满楼。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1885'),
          JobArtifactStat(name: '属性攻', value: '128'),
          JobArtifactStat(name: '会心', value: '34'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'xiaoyao': JobArtifact(
    weapon: '折扇',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '清风揽月扇',
        intro: '逍遥派文士之器，扇骨取凌云竹，看似轻摇慢捻，暗藏机关。',
        stats: [
          JobArtifactStat(name: '攻击', value: '370'),
          JobArtifactStat(name: '属性攻', value: '34'),
          JobArtifactStat(name: '会心', value: '8'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '流云听风扇',
        intro: '扇面绘流云听风图，内力灌注则云动风起，困敌于方寸。',
        stats: [
          JobArtifactStat(name: '攻击', value: '745'),
          JobArtifactStat(name: '属性攻', value: '60'),
          JobArtifactStat(name: '会心', value: '14'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '惊鸿照影扇',
        intro: '扇开如惊鸿照影，虚实难辨。中者往往不知败于何时。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1215'),
          JobArtifactStat(name: '属性攻', value: '92'),
          JobArtifactStat(name: '会心', value: '22'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '逍遥天地扇',
        intro: '一扇开合便是天地，困则八方成笼，放则万法不侵。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1815'),
          JobArtifactStat(name: '属性攻', value: '136'),
          JobArtifactStat(name: '会心', value: '32'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'emei': JobArtifact(
    weapon: '双剑',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '灵犀双影剑',
        intro: '峨眉双剑，剑意相通。一剑护友，一剑退敌。',
        stats: [
          JobArtifactStat(name: '攻击', value: '365'),
          JobArtifactStat(name: '属性攻', value: '32'),
          JobArtifactStat(name: '会心', value: '8'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '玉女素心剑',
        intro: '素心剑意凝于双锋，疗伤圣品，剑光过处伤口自愈。',
        stats: [
          JobArtifactStat(name: '攻击', value: '735'),
          JobArtifactStat(name: '属性攻', value: '58'),
          JobArtifactStat(name: '会心', value: '14'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '凌波拂柳剑',
        intro: '剑走凌波，拂柳成伤。医者仁心亦有不怒之威。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1200'),
          JobArtifactStat(name: '属性攻', value: '88'),
          JobArtifactStat(name: '会心', value: '22'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '皓月清辉剑',
        intro: '双剑合璧如皓月清辉普照，救人于危难，诛敌于须臾。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1790'),
          JobArtifactStat(name: '属性攻', value: '132'),
          JobArtifactStat(name: '会心', value: '32'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'wudang': JobArtifact(
    weapon: '长剑',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '玄天真武剑',
        intro: '真武荡魔之意入剑，剑气绵长，攻守相济。',
        stats: [
          JobArtifactStat(name: '攻击', value: '375'),
          JobArtifactStat(name: '属性攻', value: '32'),
          JobArtifactStat(name: '会心', value: '8'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '太极衍道剑',
        intro: '剑随太极，衍化阴阳。以柔克刚，后发先至。',
        stats: [
          JobArtifactStat(name: '攻击', value: '750'),
          JobArtifactStat(name: '属性攻', value: '58'),
          JobArtifactStat(name: '会心', value: '14'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '紫霄御雷剑',
        intro: '紫霄宫雷法注入剑身，剑出雷鸣，正道之声。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1225'),
          JobArtifactStat(name: '属性攻', value: '88'),
          JobArtifactStat(name: '会心', value: '22'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '荡魔倚天剑',
        intro: '倚天不出，谁与争锋。武当镇山之器，一剑荡尽天下魔。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1830'),
          JobArtifactStat(name: '属性攻', value: '132'),
          JobArtifactStat(name: '会心', value: '32'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'xingxiu': JobArtifact(
    weapon: '毒杖',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '幽泉引魂杖',
        intro: '星宿海毒泉之铁铸杖，杖头青芒隐现，近之则毒发。',
        stats: [
          JobArtifactStat(name: '攻击', value: '370'),
          JobArtifactStat(name: '属性攻', value: '34'),
          JobArtifactStat(name: '会心', value: '8'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '蚀骨噬心杖',
        intro: '七十二种奇毒炼入杖身，中毒者蚀骨噬心，苦不堪言。',
        stats: [
          JobArtifactStat(name: '攻击', value: '745'),
          JobArtifactStat(name: '属性攻', value: '60'),
          JobArtifactStat(name: '会心', value: '14'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '万蛊朝宗杖',
        intro: '万蛊淬炼，杖出毒雾弥漫，方圆之内寸草不生。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1215'),
          JobArtifactStat(name: '属性攻', value: '92'),
          JobArtifactStat(name: '会心', value: '22'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '幽冥毒龙杖',
        intro: '幽冥毒龙盘踞杖首，毒之极致，闻风丧胆。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1815'),
          JobArtifactStat(name: '属性攻', value: '136'),
          JobArtifactStat(name: '会心', value: '32'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
  'murong': JobArtifact(
    weapon: '家传剑',
    tiers: [
      JobArtifactTier(
        lv: 42,
        name: '还施彼身剑',
        intro: '姑苏慕容家传之剑，剑招借力打力，以彼之道还施彼身。',
        stats: [
          JobArtifactStat(name: '攻击', value: '375'),
          JobArtifactStat(name: '属性攻', value: '32'),
          JobArtifactStat(name: '会心', value: '9'),
        ],
        extra: '神兵共鸣：攻击有 3% 概率伤害 +5%，持续 5 秒',
        how: [
          '苏州 · 欧阳冶处接取「血浴神节」',
          '击杀 5000 只怪物，获得「残缺的神节」',
          '收集 新莽神符 ×5（三环 / 水牢 / 门派贡献兑换）',
          '回苏州修复神节，激活 42 级神器',
        ],
      ),
      JobArtifactTier(
        lv: 62,
        name: '斗转星移剑',
        intro: '斗转星移剑意所铸，敌之攻势皆可为己所用。',
        stats: [
          JobArtifactStat(name: '攻击', value: '750'),
          JobArtifactStat(name: '属性攻', value: '58'),
          JobArtifactStat(name: '会心', value: '15'),
        ],
        extra: '共鸣概率提升至 5%，伤害加成提升至 8%',
        how: [
          '等级达标后接「二代神器 · 再铸神兵」',
          '收集 神节·贰（星宿海精英掉落）',
          '收集 新莽神符·贰 ×10',
          '于欧阳冶处重铸，继承强化等级',
        ],
      ),
      JobArtifactTier(
        lv: 82,
        name: '参合凌天剑',
        intro: '参合庄秘藏，集慕容氏三代剑学之大成。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1225'),
          JobArtifactStat(name: '属性攻', value: '88'),
          JobArtifactStat(name: '会心', value: '23'),
          JobArtifactStat(name: '破防', value: '180'),
        ],
        extra: '共鸣期间额外获得 300 点破防',
        how: [
          '完成「三代神器 · 问鼎江湖」任务链',
          '收集 神节·叁 与 新莽神符·叁 ×15',
          '通关门派副本首领取「神铁之心」',
          '重铸为 82 级神器，解锁共鸣强化',
        ],
      ),
      JobArtifactTier(
        lv: 102,
        name: '姑苏烟雨剑',
        intro: '烟雨朦胧处剑光乍现，慕容世家百年底蕴，尽在此剑。',
        stats: [
          JobArtifactStat(name: '攻击', value: '1830'),
          JobArtifactStat(name: '属性攻', value: '132'),
          JobArtifactStat(name: '会心', value: '33'),
          JobArtifactStat(name: '破防', value: '320'),
        ],
        extra: '共鸣可叠加 2 层，触发时回复 2% 气血',
        how: [
          '「神兵谱 · 巅峰神铸」任务开启',
          '收集 陨铁神符 ×20（帮会演练堂 / 世界首领）',
          '熔铸 上古神铁，淬炼 神节·肆',
          '铸成 102 级巅峰神器，全属性质变',
        ],
      ),
    ],
  ),
};
