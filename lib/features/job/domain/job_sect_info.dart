/// 门派介绍 —— 领域模型与数据（与 UI 原型 `SECT_INFO` 一致）。
///
/// 十二大门派各含：一段简介（intro）、主要属性（atk / main / atype）、
/// 4 条特色（traits，如 定位 · 外功坦辅）、背景渊源（bg）、门派生活技能（life，
/// 可空）与适合人群（suit）。属性倾向权重见 `job_point.dart` 的 `kJobWeights`。
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

/// 一门派生活技能（`SECT_INFO[].life[]`）。
@immutable
class JobLifeSkill {
  const JobLifeSkill({required this.name, required this.desc, this.at});

  final String name;

  /// 效果说明。
  final String desc;

  /// 学习地点（可空，如 峨嵋山韩映雪（43，108））。
  final String? at;
}

/// 门派介绍。
@immutable
class JobSectInfo {
  const JobSectInfo({
    required this.intro,
    required this.atk,
    required this.atkColor,
    required this.main,
    required this.atype,
    required this.traits,
    required this.suit,
    this.bg = '',
    this.life = const [],
  });

  final String intro;

  /// 主属性攻标签（如 玄攻 · 主属性攻；`SECT_INFO[].atk`）。
  final List<String> atk;

  /// 主要属性色类（red / green / cyan / purple，对应原型 `xg`）。
  final String atkColor;

  /// 主修属性（如 体力 · 力量；`SECT_INFO[].main`）。
  final String main;

  /// 攻系（如 外功 · 坦辅；`SECT_INFO[].atype`）。
  final String atype;

  /// 门派特色（按原型顺序：定位 / 主修 / 武器 / 特色）。
  final List<JobTrait> traits;

  /// 适合人群。
  final String suit;

  /// 背景渊源（`SECT_INFO[].bg`，可多行）。
  final String bg;

  /// 门派生活技能（可空）。
  final List<JobLifeSkill> life;
}

/// 十二大门派介绍（对应原型 `SECT_INFO`）。
const Map<String, JobSectInfo> kJobSectInfo = {
  'shaolin': JobSectInfo(
    intro: '少林弟子武功底蕴深厚，外家功夫天下第一，面对威胁时往往舍生取义，掩护同伴，是战友们最可靠的屏障。',
    atk: ['玄攻 · 主属性攻'],
    atkColor: 'purple',
    main: '体力 · 力量',
    atype: '外功 · 坦辅',
    traits: [JobTrait(label: '定位', value: '近战攻击，单玄属性'), JobTrait(label: '武器', value: '枪棒类'), JobTrait(label: '特色', value: '少林弟子武功底蕴深厚，外家功夫天下第一，面对…'), JobTrait(label: '生活', value: '开光')],
    suit: '适合喜欢正面承伤、保护队友，享受团队核心位置的玩家。',
    bg: '中原第一名刹，佛家圣地。唐宋以来，佛教大兴，也有众多慕名之人，尘缘未断，被收留寺中，做了俗家弟子。由于天下武功出少林，所以俗家少林弟子往往心系武学，也学有所成。少林鼎盛时僧俗弟子上千，称得上武林中第一大门派。',
    life: [JobLifeSkill(name: '开光', desc: '可以制作出在一定时间内增加力量、体力、玄攻击、毒抗性等效果的物品。', at: '少林寺玄渡（128，86）'), JobLifeSkill(name: '佛法', desc: '辅助开光的技能，降低少林的生活消耗，少林独有的生活技能。可花费经验和金钱学习并且升级。', at: '少林寺玄鸣（135，90）')],
  ),
  'mingjiao': JobSectInfo(
    intro: '明教弟子外功攻击位列十二大门派之首，同时带有圣火的灼伤效果，武功先发制人，而自带的复活能力也常使他们反败为胜。',
    atk: ['火攻 · 主属性攻'],
    atkColor: 'red',
    main: '力量 · 身法',
    atype: '外功 · 爆发',
    traits: [JobTrait(label: '定位', value: '近战攻击，单火属性。'), JobTrait(label: '武器', value: '枪棒类'), JobTrait(label: '特色', value: '明教弟子外功攻击位列十二大门派之首，同时带有…'), JobTrait(label: '生活', value: '圣火术')],
    suit: '适合追求极限爆发、享受斩杀快感的进攻型玩家。',
    bg: '光明顶上，圣火熊熊。\n自唐以来，波斯拜火圣教在中国广为传播，中南东南部为甚，称为明教。\n大宋开国以来，明教教众聚集成军，屡次与朝廷发生冲突，称为江湖一大势力。\n哪里有圣火，哪里就是光明顶，哪里就有明教弟子的身影。明教弟子涉足江湖之事本来不多，但圣教行为被各大名门正派视为异端，所以也在百年间积累下众多恩怨情仇，越演越烈。',
    life: [JobLifeSkill(name: '圣火术', desc: '可以制作出在一定时间内增加力量、身法、火攻击、冰抗性、减火抗等效果的物品。', at: '光明顶仇道人（87，61）'), JobLifeSkill(name: '采火术', desc: '辅助圣火术的技能，降低圣火术的生活消耗，明教独有的生活技能。可花费经验和金钱学习并且升级。', at: '光明顶方天定（87，58）')],
  ),
  'gaibang': JobSectInfo(
    intro: '丐帮弟子擅长近身搏击，腾挪闪避之术天下无双，连击越多，攻击力越大，战斗中往往愈战愈强，后发制人。',
    atk: ['毒攻 · 主属性攻'],
    atkColor: 'green',
    main: '力量 · 体力',
    atype: '外功 · 持续',
    traits: [JobTrait(label: '定位', value: '近战攻击，火毒双属性。'), JobTrait(label: '武器', value: '枪棒类'), JobTrait(label: '特色', value: '丐帮弟子擅长近身搏击，腾挪闪避之术天下无双，…'), JobTrait(label: '生活', value: '酿酒')],
    suit: '适合喜欢持久作战、稳扎稳打的消耗流玩家。',
    bg: '天做棉被地当床，残羹剩汤百家尝。\n笑对人间沧桑事，看尽世态道炎凉。\n莫问英雄何出身，万众一心盼国强。\n经过几代帮主的建设，聚集在中原的数万丐帮弟子，实际上已经成为武林最大的帮派势力。丐帮总舵，戒备森严，可外抵强虏，内抗朝廷。在丐帮弟子身上，也往往具备一种令人折服的英雄气概。',
    life: [JobLifeSkill(name: '酿酒', desc: '可以制作出在一定时间内增加力量、闪避、毒攻击、玄抗性等效果的物品。', at: '丐帮总舵吴长风（114，91）'), JobLifeSkill(name: '莲花落', desc: '辅助酿酒的技能，降低酿酒的生活消耗，是丐帮的独有技能。可花费经验和金钱学习并且升级。', at: '丐帮总舵上官长雨（131，83）')],
  ),
  'tianshan': JobSectInfo(
    intro: '天山弟子的武功以诡异著称，是天生的刺客，战斗中身形飘忽，可以瞬间隐没自己，待合适时机爆发，实行一击必杀。',
    atk: ['冰攻 · 主属性攻'],
    atkColor: 'cyan',
    main: '身法 · 力量',
    atype: '外功 · 刺客',
    traits: [JobTrait(label: '定位', value: '近战攻击，单冰属性'), JobTrait(label: '武器', value: '扇环类'), JobTrait(label: '特色', value: '天山弟子的武功以诡异著称，是天生的刺客，战斗…'), JobTrait(label: '生活', value: '玄冰术')],
    suit: '适合钟情潜行刺杀、追求操作与瞬间爆发的玩家。',
    bg: '灵鹫宫远在天山，经过几十年的经营，却悄悄控制着中原至东南沿海大多数江湖帮会。所以江湖上谈起天山派，不谈"天山"，往往用"宫里"代替。\n灵鹫宫当然不在雪山峰顶，而是在天山南麓一处温暖湿润的所在。众多弟子居住于此，灵鹫宫实际上既是集市、也是城堡。因为方圆百里皆是其控制范围，所以灵鹫宫从未经过刀光剑影，一派安乐祥和景象。\n天山童姥是天山唯一的神，见过她面目的人少之又少，大多数人只是从血腥的江湖故事里听到过这个恐怖的名字。',
    life: [JobLifeSkill(name: '玄冰术', desc: '可以制作出在一定时间内增加体力、身法、闪避、命中、冰攻击、火抗性、减冰抗等效果的物品。', at: '天山余婆（119，67）'), JobLifeSkill(name: '采冰术', desc: '辅助玄冰术的技能，降低玄冰术的活力消耗，是天山的独有技能。可花费经验和金钱学习并且升级。', at: '天山石嫂（123，67）')],
  ),
  'xiaoyao': JobSectInfo(
    intro: '逍遥弟子武功博大精深，奇门遁甲控敌之术无敌于天下，神出鬼没让敌人防不胜防，群战中更是令人胆寒。',
    atk: ['火攻 · 主属性攻', '毒攻 · 副属性攻'],
    atkColor: 'red',
    main: '灵气 · 身法',
    atype: '内功 · 控制',
    traits: [JobTrait(label: '定位', value: '远程攻击，火毒双属性。'), JobTrait(label: '武器', value: '扇环类'), JobTrait(label: '特色', value: '逍遥弟子武功博大精深，奇门遁甲控敌之术无敌于…'), JobTrait(label: '生活', value: '奇门遁甲')],
    suit: '适合擅长游走控制、以智取胜的策略型玩家。',
    bg: '斜日半山，暝烟两岸，数声横笛，一叶扁舟。\n风过处凌波微微，水映玉璧，掩映着逍遥所在神仙府－凌波洞。\n逍遥派弟子不多，也不聚集成群，有朝廷为官者也有游荡市井者，从某种意义上说其实就是逍遥子一人之门派，逍遥子在哪里哪里就是逍遥派所在。所以江湖有云"未曾见过逍遥的人，只曾听过逍遥的事"。\n凌波洞并不像人们想象的奢华铺张，反而显得崚峋简陋，还经常人去洞空。但凌波洞总对逍遥子有特殊的意义，几年里总有些日子凌波洞会有人间烟火。',
    life: [JobLifeSkill(name: '奇门遁甲', desc: '可以制作出在一定时间内增加灵气、体力、身法、闪避、命中、毒攻击、火攻击的物品。', at: '逍遥冯阿三（62，68）'), JobLifeSkill(name: '六艺风骨', desc: '辅助奇门遁甲的技能，降低奇门遁甲的生活消耗，是逍遥派的独有技能。可花费经验和金钱学习并且升级。', at: '逍遥石清露（53，150）')],
  ),
  'emei': JobSectInfo(
    intro: '峨嵋弟子擅长治疗，同时拥有强大的攻击力与自保能力。',
    atk: ['冰攻 · 主属性攻', '玄攻 · 副属性攻'],
    atkColor: 'cyan',
    main: '灵气 · 体力',
    atype: '内功 · 治疗',
    traits: [JobTrait(label: '定位', value: '远程攻击，冰玄双属性'), JobTrait(label: '武器', value: '单短类，双短类'), JobTrait(label: '特色', value: '峨嵋弟子擅长治疗，同时拥有强大的攻击力与自保…'), JobTrait(label: '生活', value: '制符')],
    suit: '适合乐于辅助队友、掌控战局节奏的治疗向玩家。',
    bg: '大峨两山相对开，小峨迤逦中峨来，三峨秀色甲天下，何须涉海寻蓬莱。\n峨嵋山，神韵灵秀，同时是佛、道两教的名山，从唐朝起始有习武之人，不过当时峨嵋派在整个武林还是默默无闻。\n几十年前，大宋水军沿江而上，一举灭亡了蜀国。蜀国的高手很多隐居至峨嵋山，渐渐的，使得峨嵋崭露头角，成为江湖中的一大门派。',
    life: [JobLifeSkill(name: '制符', desc: '可以制作出在一定时间内增加各种抗性效果和冰攻击的物品。', at: '峨嵋山韩映雪（43，108）'), JobLifeSkill(name: '灵心术', desc: '辅助制符的技能，降低制符的活力消耗，是峨嵋的独有技能。可花费经验和金钱学习并且升级。', at: '峨嵋山扈三娘（39，109）')],
  ),
  'wudang': JobSectInfo(
    intro: '武当弟子道法深厚，武功博大雄浑，内功位列十二大门派之首，攻敌于百步之外，同时可以移形换位，几乎能做到敌不沾身。',
    atk: ['玄攻 · 主属性攻'],
    atkColor: 'purple',
    main: '灵气 · 体力',
    atype: '内功 · 均衡',
    traits: [JobTrait(label: '定位', value: '远程攻击，冰玄双属性'), JobTrait(label: '武器', value: '单短类，双短类'), JobTrait(label: '特色', value: '武当弟子道法深厚，武功博大雄浑，内功位列十二…'), JobTrait(label: '生活', value: '炼丹')],
    suit: '适合偏好攻守兼备、稳健全面的全能型玩家。',
    bg: '亘古无双胜境，天下第一仙山。\n武当山集幽、奇、秀、美为一体，四季风光不同，景色各异。自南北朝起这里就有众多武林中人隐修于此，武当派最初只是在此修道隐居之人的松散朋党。\n自第一代天师起，武当越来越紧密的成为江湖上难以忽视的派别，近几十年更是可以和少林相提并论，隐隐有武林领袖的风范。\n武当派并非道观，却深喑道法，收藏众多道学经典。皇上欲修《道经》，就选取了声名渐隆的武当山。',
    life: [JobLifeSkill(name: '炼丹', desc: '可以制作出在一定时间内增加灵力、体力、玄攻击、毒抗性、减玄抗等效果的物品。', at: '武当山鹤云道人（44，56）'), JobLifeSkill(name: '道法', desc: '辅助炼丹的技能，降低炼丹的生活消耗，是武当的独有技能。可花费经验和金钱学习并且升级。', at: '武当山宁虚散人（41，58）')],
  ),
  'xingxiu': JobSectInfo(
    intro: '星宿弟子是名门正派天生的敌人，用毒之术精深无比，与他们对战，容易被扰乱心智恐惧不已，更需忍受持续的剧毒伤害。',
    atk: ['毒攻 · 主属性攻'],
    atkColor: 'green',
    main: '灵气 · 体力',
    atype: '内功 · 毒系',
    traits: [JobTrait(label: '定位', value: '远程攻击，单毒属性。'), JobTrait(label: '武器', value: '单短类，双短类'), JobTrait(label: '特色', value: '星宿弟子是名门正派天生的敌人，用毒之术精深无…'), JobTrait(label: '生活', value: '制毒')],
    suit: '适合喜欢持续侵蚀、折磨流打法的玩家。',
    bg: '星宿海深深的躲在荒原的绿洲里，常年的雨水积累成湖。\n星宿派并非存在于大宋领土之上，而是靠着自己的力量顽强的在塞外生存着。\n这是一个由不臣服于西夏的汉人边民组成的草民力量，丁春秋把这个力量发展成为一个最强大的门派之一，所以在星宿里，不该有人不认为丁春秋就是神。',
    life: [JobLifeSkill(name: '制毒', desc: '可以制作出在一定时间内增加血上限、气上限、玄抗性、毒攻击、减毒抗等效果的物品。', at: '星宿摘星子（101，87）'), JobLifeSkill(name: '引虫术', desc: '辅助制毒技能，降低制毒的活力消耗，星宿派独有的生活技能。', at: '星宿狮吼子（101，89）')],
  ),
  'murong': JobSectInfo(
    intro: '姑苏慕容氏，以彼之道还施彼身。家传剑法借力打力，内外兼修，深不可测。',
    atk: ['玄攻 · 主属性攻'],
    atkColor: 'purple',
    main: '力量 · 灵气',
    atype: '内外 · 兼修',
    traits: [JobTrait(label: '定位', value: '内外兼修'), JobTrait(label: '主修', value: '力量 灵气'), JobTrait(label: '武器', value: '家传剑'), JobTrait(label: '特色', value: '斗转星移，反制博弈')],
    suit: '适合讲究反制博弈、钟意门派背景的情怀玩家。',
    bg: '姑苏城外燕子坞，参合庄上还施水阁。慕容氏乃五胡十六国燕国皇裔，国破之后世代隐居姑苏，立誓复兴大燕，故家传武学皆以「以彼之道，还施彼身」为宗。水阁之中藏尽天下武学典籍，庄中子弟对各门各派的招式信手拈来。江湖上凡遇诡异伤人案，总有人脱口而出——「姑苏慕容，干的？」',
    life: [],
  ),
  'erengu': JobSectInfo(
    intro: '毁誉扰扰皆黄土，是非昭昭自在心。恶人谷弟子以冷镰为器，拘魂驭鬼，是游走于暗影中的远程刺客。',
    atk: ['毒冰 · 双属性攻'],
    atkColor: 'green',
    main: '灵气 · 身法',
    atype: '内功 · 刺客',
    traits: [JobTrait(label: '定位', value: '远程刺客'), JobTrait(label: '主修', value: '灵气 身法'), JobTrait(label: '武器', value: '冷镰'), JobTrait(label: '特色', value: '拘魂驭鬼，三魂七煞')],
    suit: '适合喜欢高风险高回报、讲究拘魂状态资源管理与爆发节奏的刺客玩法玩家。',
    bg: '毁誉扰扰皆黄土，是非昭昭自在心。恶人谷，江湖中人人闻之色变之地，却也是天下恶人最后的容身之所。谷中弟子行事只凭本心，恩怨分明——恶要作尽，义也守到极处。他们以冷镰为器，修煅骨通脉之术，拘天地命三魂于敌身：魂在己手，则伤敌愈深；魂被拘者，百业俱废。门派属性毒、冰双修，定位远程刺客，来去如风，一击封喉。（数据源自畅游官网「全新门派恶人谷」专题）',
    life: [],
  ),
  'tianlong': JobSectInfo(
    intro: '天龙弟子内、外兼修，同时拥有数种攻击属性，以指为剑，命中极高，更可隔空点穴，制敌于数米之外。',
    atk: ['冰火玄毒 · 四属性'],
    atkColor: 'purple',
    main: '灵气 · 身法',
    atype: '内外 · 兼修',
    traits: [JobTrait(label: '定位', value: '内外兼修'), JobTrait(label: '主修', value: '灵气 身法'), JobTrait(label: '武器', value: '扇环类'), JobTrait(label: '特色', value: '以指为剑，四象俱融')],
    suit: '适合喜欢多属性自由切换、稳定命中与中远程节奏输出的玩家。',
    bg: '下关风、上关花、苍山雪、洱海月。\n点苍山十三峰巍巍而立，俯视着洱海之畔的百里之国－大理。\n大理皇室出身中原武林，笃信佛教，历来皇室子弟多出家苍山天龙寺。在佛院钟声里，隐藏着段氏一辈一辈高手，这个强大的力量是这个国家真正的根基。\n中原武林称之为"天龙"，位十二大门派之列。（背景资料源自畅游官网游戏资料站「十二大门派」）',
    life: [JobLifeSkill(name: '制蛊', desc: '可以制作出在一定时间内增加灵力、体力、身法、命中、闪避等效果的物品。', at: '天龙寺本相（35，86）'), JobLifeSkill(name: '经脉百诀', desc: '辅助制蛊的技能，降低制蛊的活力消耗，是天龙的独有技能。可花费经验和金钱学习并且升级。', at: '天龙寺本参（64，151）')],
  ),
  'mantuo': JobSectInfo(
    intro: '以器伤身，怎敌以情诛心？曼陀山庄世代擅琴，耳得之为声者以技奏之，心得之为声者以情奏之，借琴弦拨动对方心弦，辅以香料，或助人养神，或克敌制胜。',
    atk: ['玄攻 · 主属性攻'],
    atkColor: 'purple',
    main: '灵气 · 体力',
    atype: '内功 · 琴音',
    traits: [JobTrait(label: '定位', value: '内功琴音'), JobTrait(label: '主修', value: '灵气 体力'), JobTrait(label: '武器', value: '琴'), JobTrait(label: '特色', value: '玄音流芳，以情诛心')],
    suit: '适合喜欢中远程节奏输出、讲究曼陀花资源循环，钟情琴音花语美学的玩家。',
    bg: '姑苏太湖之畔，曼陀山庄遍植山茶曼陀，四时花气袭人。山庄世代擅琴，历代庄主精进不辍，以达动人心弦之境——唯有情满意沛、心思恪纯者，方可借琴弦拨对方心弦，借琴音弥散，动其六欲七情，和其脏腑神志；再辅以秘制香料，或助人养神，或克敌制胜。第十大门派曼陀山庄以「玄音曲」「流芳诀」双系传世：玄音曲以琴音玄劲远攻伤敌，流芳诀以曼陀花为引爆发制胜。（背景资料源自畅游官网「第十大门派曼陀山庄上线」专题）',
    life: [],
  ),
};
