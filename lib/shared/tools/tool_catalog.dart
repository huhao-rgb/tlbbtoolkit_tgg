import 'package:flutter/material.dart';

/// 天工阁 · 工具目录（跨 feature 共享的单一数据源）。
///
/// 三个工具 feature（pet 珍兽 / job 职业 / misc 实用）的
/// hub 与工具元信息集中于此，供以下模块共同消费：
/// - `home`（首页工具网格、分类筛选、搜索）；
/// - 各 feature 的 hub 页与工具占位页；
/// - 路由命名（`@TypedGoRoute(name:)` 与页面保持一致）；
/// - 一致性测试（路由 location ↔ 目录 location）。
///
/// 文案与《天工阁-UI原型.html》(v1.13.0，兽灵手风琴版) 对齐；图标暂用
/// Material 图标占位，后续替换为 `svg_icons/` 线性图标。
///
/// 一级分类（[categories]）为 珍兽 / 职业 / 实用 三类：兽灵 · 兽魂已并入
/// 珍兽，不再是独立一级分类，仅作为卡片图钉配色分组（[beast]）保留。
enum ToolGroup {
  pet(
    path: 'pet',
    label: '珍兽',
    short: '珍兽',
    tabIcon: 'paw',
    hubTitle: '珍兽工具',
    hubCrumb: '珍兽 PET',
    hubSubtitle: '资质、技能、套装、兽魂、图鉴 —— 从选宠到成品的全套工具',
  ),
  // 兽灵 · 兽魂：一级页已移除，6 个珍兽工具中属兽灵系统的 3 个（兽魂查询 /
  // 兽灵图鉴 / 兽灵技能效果）仍以此为 [ToolDef.group]，用于卡片图钉取紫色
  // （原型 `.tile.beast`）；归属分类见 [category]。
  beast(
    path: 'beast',
    label: '兽灵 · 兽魂',
    short: '珍兽',
    tabIcon: 'gem',
    hubTitle: '珍兽工具',
    hubCrumb: '珍兽 PET',
    hubSubtitle: '资质、技能、套装、兽魂、图鉴 —— 从选宠到成品的全套工具',
  ),
  job(
    path: 'job',
    label: '职业',
    short: '职业',
    tabIcon: 'sword',
    hubTitle: '职业中心',
    hubCrumb: '职业 CLASS',
    hubSubtitle: '武道、技能、加点 —— 十二大门派的修炼手册',
  ),
  misc(
    path: 'misc',
    label: '实用',
    short: '实用',
    tabIcon: 'spark',
    hubTitle: '实用工具',
    hubCrumb: '实用 TOOLS',
    hubSubtitle: '账号管理 · 周期计时 —— 日常实用小工具合集',
  );

  const ToolGroup({
    required this.path,
    required this.label,
    required this.short,
    required this.tabIcon,
    required this.hubTitle,
    required this.hubCrumb,
    required this.hubSubtitle,
  });

  /// 路由段（也是首页分类 `data-cat`、URL 首段）。
  final String path;

  /// 分类短名：首页筛选 chip（也是工具页面包屑首段）。
  final String label;

  /// 面包屑链接文本。
  final String short;

  /// 移动端底部 tab 图标资产名（首页单独为 home）。
  final String tabIcon;

  /// hub 页标题 / 面包屑尾段。
  final String hubTitle;
  final String hubCrumb;
  final String hubSubtitle;

  /// 归属一级分类的 hub 路由 location（如 `/pet`）。
  ///
  /// [beast] 返回 `/pet`：兽灵 · 兽魂一级页已移除，其工具挂在珍兽 hub 下；
  /// 若仍返回 `/beast` 会指向不存在的路由。
  String get hubLocation => '/${category.path}';

  /// 归属的一级分类。
  ///
  /// 仅 [beast] 例外：兽灵 · 兽魂已并入珍兽，其工具在 hub / 首页筛选 / 侧栏
  /// 分组中一律归到 [pet]；自身仅用于卡片图钉配色。
  ToolGroup get category => this == beast ? pet : this;

  /// 一级分类顺序（首页 chips / 移动 tab / 侧栏分组）。
  ///
  /// 与 [values]（含已并入珍兽的 [beast]）不同，因此各处分组遍历本列表。
  static const List<ToolGroup> categories = [pet, job, misc];
}

/// 单个工具的元信息。
@immutable
class ToolDef {
  const ToolDef({
    required this.id,
    required this.group,
    required this.title,
    required this.crumb,
    required this.pageSubtitle,
    required this.cardDesc,
    required this.keywords,
    required this.location,
    required this.icon,
    this.category,
    this.isHot = false,
  });

  /// 稳定 id（如 `pet-calc`），对应原型视图 `v-<id>` 后缀。
  final String id;

  /// 分组（决定卡片图钉配色：pet 金 / beast 紫 / job 蓝 / misc 金）。
  final ToolGroup group;

  /// 归属的一级分类；缺省跟随 [group]（仅兽灵三工具显式传 `pet`）。
  final ToolGroup? category;

  /// 统一标题（路由 name / 信息条 / 页头 h1 / 卡片名）。
  final String title;

  /// 工具页头面包屑，如 `珍兽 / 资质计算`。
  final String crumb;

  /// 工具页头副标题（取自原型 page-head `<p>`）。
  final String pageSubtitle;

  /// 首页 / hub 卡片描述。
  final String cardDesc;

  /// 首页搜索命中词。
  final List<String> keywords;

  /// 路由 location（与 feature 内嵌套路由一致），如 `/pet/calc`。
  final String location;

  /// SVG 图标资产名（`assets/icons/<icon>.svg`，flutter_gen 生成，经 `TgIcon` 渲染）。
  final String icon;

  /// 是否「热门」角标。
  final bool isHot;

  /// 面包屑首段（可点击返回 hub 的文案，取分组短名）。
  String get crumbRoot => group.short;
}

/// 首页顶部统计（演示值，随数据接入后改为按库统计）。
class HomeStat {
  const HomeStat(this.value, this.label);

  final int value;
  final String label;
}

/// 工具目录常量表。
abstract final class ToolCatalog {
  // ---- 珍兽 pet ----
  static const ToolDef petCalc = ToolDef(
    id: 'pet-calc',
    group: ToolGroup.pet,
    title: '珍兽资质计算',
    crumb: '珍兽 / 资质计算',
    pageSubtitle: '输入当前资质与悟灵状态，预估培养至目标悟灵后的成品资质、评级与成长空间',
    cardDesc: '成长率 × 悟性 × 灵性，预估成品资质与评级',
    keywords: ['资质', '计算', '宝宝', '珍兽', '成长率', '悟性', '灵性', '内功', '外功', '超灵'],
    location: '/pet/calc',
    icon: 'calc',
    isHot: true,
  );

  static const ToolDef petProb = ToolDef(
    id: 'pet-prob',
    group: ToolGroup.pet,
    title: '珍兽技能释放概率',
    crumb: '珍兽 / 技能概率',
    pageSubtitle: '按性格查看自动 / 状态 / 辅助技能的触发概率与判定方式',
    cardDesc: '自动 / 状态 / 辅助技能触发判定一览',
    keywords: ['技能', '概率', '释放', '触发', '判定', '猛击', '连击', '附身'],
    location: '/pet/prob',
    icon: 'pct',
  );

  static const ToolDef petSuit = ToolDef(
    id: 'pet-suit',
    group: ToolGroup.pet,
    title: '珍兽套装图鉴',
    crumb: '珍兽 / 套装图鉴',
    pageSubtitle: '怀旧服 75 / 85 / 95 三档 22 个珍兽套装系列 · 全套效果与圣兽鳞消耗',
    cardDesc: '22 个珍兽套装系列 · 全套效果与圣兽鳞消耗',
    keywords: [
      '套装',
      '图鉴',
      '宝宝',
      '珍兽',
      '圣兽鳞',
      '苍狼啸月',
      '黄雀戏水',
      '猛虎越山',
      '雄狮逆鳞',
      '升星',
    ],
    location: '/pet/suit',
    icon: 'shield',
  );

  // ---- 兽灵系统（并入珍兽分类；图钉仍取紫色 .tile.beast） ----
  static const ToolDef beastSoul = ToolDef(
    id: 'beast-soul',
    group: ToolGroup.beast,
    category: ToolGroup.pet,
    title: '兽魂查询',
    crumb: '珍兽 / 兽魂查询',
    pageSubtitle: '按类型筛选十五大兽魂，速查出战技能与融魂技能',
    cardDesc: '十五大兽魂 · 出战 / 融魂技能速查',
    keywords: ['兽魂', '神兽魂', '荒兽魂', '灵兽魂', '出战技能', '融魂技能', '火攻', '冰攻'],
    location: '/pet/beast/soul',
    icon: 'flame',
  );

  static const ToolDef beastIndex = ToolDef(
    id: 'beast-index',
    group: ToolGroup.beast,
    category: ToolGroup.pet,
    title: '兽灵图鉴',
    crumb: '珍兽 / 图鉴',
    pageSubtitle: '珍兽觉醒缔约 · 兽灵附体强化存活与输出 · 依据官方公告与玩家实测整理（2025-03 上线）',
    cardDesc: '20 级 7 阶 · 兽灵技能逐阶效果速查',
    keywords: [
      '兽灵',
      '图鉴',
      '技能',
      '阶位',
      '效果',
      '破御',
      '破胆',
      '冰精',
      '拼命',
      '痛击',
      '连击',
      '灵动',
      '20级',
      '7阶',
    ],
    location: '/pet/beast/index',
    icon: 'gem',
  );

  static const ToolDef beastSkill = ToolDef(
    id: 'beast-skill',
    group: ToolGroup.beast,
    category: ToolGroup.pet,
    title: '兽灵技能效果',
    crumb: '珍兽 / 技能效果',
    pageSubtitle: '点击展开 Lv.1-5 等级数值表',
    cardDesc: 'Lv.1-5 等级数值表 · 触发条件',
    keywords: ['兽灵', '技能', '等级', '效果', '数值', '冷却'],
    location: '/pet/beast/skill',
    icon: 'spark',
  );

  // ---- 职业 job ----
  static const ToolDef jobWudao = ToolDef(
    id: 'job-wudao',
    group: ToolGroup.job,
    title: '职业武道',
    crumb: '职业 / 武道',
    pageSubtitle: '选择门派，查看攻伐与御守两条武道路线',
    cardDesc: '九派武道境界 · 逐重效果与推荐路线',
    keywords: ['武道', '门派', '境界', '重数', '攻伐', '御守'],
    location: '/job/wudao',
    icon: 'sword',
  );

  static const ToolDef jobSkill = ToolDef(
    id: 'job-skill',
    group: ToolGroup.job,
    title: '职业技能库',
    crumb: '职业 / 技能库',
    pageSubtitle: '按门派查看技能类型、冷却与完整描述',
    cardDesc: '类型 · 冷却 · 完整技能描述速查',
    keywords: ['职业技能', '门派', '冷却', '伤害', '描述'],
    location: '/job/skill',
    icon: 'book',
  );

  static const ToolDef jobPoint = ToolDef(
    id: 'job-point',
    group: ToolGroup.job,
    title: '职业加点计算器',
    crumb: '职业 / 加点',
    pageSubtitle: '潜能点分配 · 一键推荐方案 · 面板预览',
    cardDesc: '五维潜能分配 · 一键推荐方案 · 面板预览',
    keywords: ['加点', '潜能', '力量', '灵气', '体力', '定力', '身法', '五维'],
    location: '/job/point',
    icon: 'slider',
    isHot: true,
  );

  static const ToolDef jobArtifact = ToolDef(
    id: 'job-artifact',
    group: ToolGroup.job,
    title: '职业神器',
    crumb: '职业 / 神器',
    pageSubtitle: '十二大门派专属神兵 · 简介 / 属性 / 获取途径 · 42-102 级',
    cardDesc: '简介 · 属性 · 获取途径 · 42-102 级',
    keywords: ['神器', '神兵', '新莽神符', '42级', '62级', '82级', '102级', '获取', '途径'],
    location: '/job/artifact',
    icon: 'sword',
  );

  static const ToolDef jobSect = ToolDef(
    id: 'job-sect',
    group: ToolGroup.job,
    title: '门派介绍',
    crumb: '职业 / 门派',
    pageSubtitle: '十二大门派背景 · 门派特色 · 属性倾向 · 适合人群',
    cardDesc: '背景 · 特色 · 属性倾向 · 适合人群',
    keywords: ['门派', '背景', '特色', '介绍', '属性', '适合'],
    location: '/job/sect',
    icon: 'shield',
  );

  // ---- 实用 misc ----
  static const ToolDef miscRegress = ToolDef(
    id: 'misc-regress',
    group: ToolGroup.misc,
    title: '卡回归计算器',
    crumb: '实用 / 卡回归计算器',
    pageSubtitle: '多账号回归周期记录 · 卡满 7 天提醒上线领奖',
    cardDesc: '多账号回归周期计时 · 满 7 天自动开启回归 · 完成记录',
    keywords: ['回归', '计算', '卡回归', '多账号', '计时', '上线', '奖励', '周期'],
    location: '/misc/regress',
    icon: 'clock',
  );

  static const ToolDef miscMarket = ToolDef(
    id: 'misc-market',
    group: ToolGroup.misc,
    title: '珍兽行情',
    crumb: '实用 / 珍兽行情',
    pageSubtitle: '神仙代售平台 · 天龙八部怀旧原始服「宝宝」类目在售数据分析',
    cardDesc: '神仙代售平台数据 · 价位分布 · 品种均价 · 性价比推荐',
    keywords: ['行情', '珍兽', '价格', '售价', '神仙代售', '均价', '性价比'],
    location: '/misc/market',
    icon: 'pct',
  );

  static const ToolDef miscAccountMarket = ToolDef(
    id: 'acc-market',
    group: ToolGroup.misc,
    title: '账号行情',
    crumb: '实用 / 账号行情',
    pageSubtitle: '神仙代售平台 · 天龙八部怀旧服「游戏账号」类目在售数据分析',
    cardDesc: '神仙代售平台数据 · 区服筛选 · 职业均价 · 性价比推荐',
    keywords: ['行情', '账号', '价格', '售价', '神仙代售', '均价', '职业', '性价比'],
    location: '/misc/acc-market',
    icon: 'user',
  );

  /// 全部 14 个工具（首页网格顺序）。
  static const List<ToolDef> all = [
    petCalc,
    petProb,
    petSuit,
    beastSoul,
    beastIndex,
    beastSkill,
    jobSect,
    jobWudao,
    jobSkill,
    jobPoint,
    jobArtifact,
    miscRegress,
    miscMarket,
    miscAccountMarket,
  ];

  /// 某一级分类下的工具（hub 页列表顺序 / 首页筛选 / 侧栏分组）。
  ///
  /// 按 [ToolDef.category]（缺省跟随 [ToolDef.group]）匹配：兽灵三工具的
  /// `group` 是 [ToolGroup.beast]（图钉取紫），`category` 为珍兽，因此会一并
  /// 出现在「珍兽工具」hub / 首页珍兽筛选 / 侧栏珍兽分组。
  static List<ToolDef> ofCategory(ToolGroup category) => all
      .where((t) => (t.category ?? t.group) == category)
      .toList(growable: false);

  /// 首页顶部统计（演示值；正式接入后改为按数据仓库统计）。
  static const List<HomeStat> homeStats = [
    HomeStat(48, '兽灵图鉴'),
    HomeStat(279, '技能数据'),
    HomeStat(24, '套装收录'),
    HomeStat(12, '门派覆盖'),
  ];
}
