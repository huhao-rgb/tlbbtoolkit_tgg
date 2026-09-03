/// 门派介绍 —— 领域模型与数据（与 UI 原型 `SECT_INFO` 一致）。
///
/// 九大门派各含：一段简介（intro）、4 条特色（traits，如 定位 · 外功坦辅）
/// 与适合人群（suit）。属性倾向权重见 `job_point.dart` 的 `kJobWeights`。
library;

import 'package:flutter/foundation.dart';

/// 一条门派特色（如 定位 / 主修 / 武器 / 特色）。
@immutable
class JobTrait {
  const JobTrait({required this.label, required this.value});

  final String label;

  /// 特色值（如 外功坦辅 / 体力 力量 …）。
  final String value;
}

/// 门派介绍。
@immutable
class JobSectInfo {
  const JobSectInfo({
    required this.intro,
    required this.traits,
    required this.suit,
  });

  final String intro;

  /// 门派特色（按原型顺序：定位 / 主修 / 武器 / 特色）。
  final List<JobTrait> traits;

  /// 适合人群。
  final String suit;
}

/// 九大门派介绍（对应原型 `SECT_INFO`）。
const Map<String, JobSectInfo> kJobSectInfo = {
  'shaolin': JobSectInfo(
    intro: '千年古刹，天下武学之宗。少林弟子以禅入武，杖法刚猛沉稳，是团队中最坚实的壁垒。',
    traits: [
      JobTrait(label: '定位', value: '外功坦辅'),
      JobTrait(label: '主修', value: '体力 力量'),
      JobTrait(label: '武器', value: '禅杖'),
      JobTrait(label: '特色', value: '金刚护体，减伤嘲讽'),
    ],
    suit: '适合喜欢正面承伤、保护队友，享受团队核心位置的玩家。',
  ),
  'mingjiao': JobSectInfo(
    intro: '光明顶上圣火熊熊，教众行事热烈而极端。明教刀法大开大合，爆发力冠绝群雄。',
    traits: [
      JobTrait(label: '定位', value: '外功爆发'),
      JobTrait(label: '主修', value: '力量 身法'),
      JobTrait(label: '武器', value: '长刀'),
      JobTrait(label: '特色', value: '怒火连斩，极限输出'),
    ],
    suit: '适合追求极限爆发、享受斩杀快感的进攻型玩家。',
  ),
  'gaibang': JobSectInfo(
    intro: '天下第一大帮，弟子遍布市井江湖。丐帮棒法绵延不绝，缠斗中越战越勇。',
    traits: [
      JobTrait(label: '定位', value: '外功持续'),
      JobTrait(label: '主修', value: '力量 体力'),
      JobTrait(label: '武器', value: '玉棒'),
      JobTrait(label: '特色', value: '连击缠斗，持久压制'),
    ],
    suit: '适合喜欢持久作战、稳扎稳打的消耗流玩家。',
  ),
  'tianshan': JobSectInfo(
    intro: '缥缈峰终年积雪，灵鹫宫隐于其上。天山身法诡谲，来去如风，于无声处取人性命。',
    traits: [
      JobTrait(label: '定位', value: '外功刺客'),
      JobTrait(label: '主修', value: '身法 力量'),
      JobTrait(label: '武器', value: '双环'),
      JobTrait(label: '特色', value: '隐身突袭，一击致命'),
    ],
    suit: '适合钟情潜行刺杀、追求操作与瞬间爆发的玩家。',
  ),
  'xiaoyao': JobSectInfo(
    intro: '逍遥派门人皆具仙风道骨，武功飘逸洒脱。一柄折扇可困敌、可自保，控制之道出神入化。',
    traits: [
      JobTrait(label: '定位', value: '内功控制'),
      JobTrait(label: '主修', value: '灵气 身法'),
      JobTrait(label: '武器', value: '折扇'),
      JobTrait(label: '特色', value: '溪山行旅，困敌四方'),
    ],
    suit: '适合擅长游走控制、以智取胜的策略型玩家。',
  ),
  'emei': JobSectInfo(
    intro: '峨眉金顶云海翻腾，弟子以医入武。双剑合璧既能济世救人，亦能诛敌于须臾。',
    traits: [
      JobTrait(label: '定位', value: '内功治疗'),
      JobTrait(label: '主修', value: '灵气 体力'),
      JobTrait(label: '武器', value: '双剑'),
      JobTrait(label: '特色', value: '清心普善，救死扶伤'),
    ],
    suit: '适合乐于辅助队友、掌控战局节奏的治疗向玩家。',
  ),
  'wudang': JobSectInfo(
    intro: '道教圣地，太极之道源远流长。武当剑法以柔克刚，攻守相济，堪称正道中流砥柱。',
    traits: [
      JobTrait(label: '定位', value: '内功均衡'),
      JobTrait(label: '主修', value: '灵气 体力'),
      JobTrait(label: '武器', value: '长剑'),
      JobTrait(label: '特色', value: '太极两仪，攻守自如'),
    ],
    suit: '适合偏好攻守兼备、稳健全面的全能型玩家。',
  ),
  'xingxiu': JobSectInfo(
    intro: '星宿海毒物遍地，门人用毒之道独步天下。毒杖所至，侵蚀不绝，令敌苦不堪言。',
    traits: [
      JobTrait(label: '定位', value: '内功毒系'),
      JobTrait(label: '主修', value: '灵气 体力'),
      JobTrait(label: '武器', value: '毒杖'),
      JobTrait(label: '特色', value: '腐尸毒，持续蚕食'),
    ],
    suit: '适合喜欢持续侵蚀、折磨流打法的玩家。',
  ),
  'murong': JobSectInfo(
    intro: '姑苏慕容氏，以彼之道还施彼身。家传剑法借力打力，内外兼修，深不可测。',
    traits: [
      JobTrait(label: '定位', value: '内外兼修'),
      JobTrait(label: '主修', value: '力量 灵气'),
      JobTrait(label: '武器', value: '家传剑'),
      JobTrait(label: '特色', value: '斗转星移，反制博弈'),
    ],
    suit: '适合讲究反制博弈、钟意门派背景的情怀玩家。',
  ),
};
