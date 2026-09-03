import 'package:flutter/material.dart';

/// 天工阁 · 工具目录（跨 feature 共享的单一数据源）。
///
/// 三个工具 feature（pet 宝宝 / beast 兽灵·兽魂 / job 职业）的
/// hub 与工具元信息集中于此，供以下模块共同消费：
/// - `home`（首页工具网格、分类筛选、搜索）；
/// - 各 feature 的 hub 页与工具占位页；
/// - 路由命名（`@TypedGoRoute(name:)` 与页面保持一致）；
/// - 一致性测试（路由 location ↔ 目录 location）。
///
/// 文案与《天工阁-UI原型.html》(v1.4.0) 对齐；图标暂用 Material 图标占位，
/// 后续替换为 `svg_icons/` 线性图标。
enum ToolGroup {
  pet(
    path: 'pet',
    label: '宝宝',
    short: '宝宝',
    hubTitle: '宝宝工具',
    hubCrumb: '宝宝 BABY',
    hubSubtitle: '资质、技能、套装 —— 从选宠到成品的三件套',
  ),
  beast(
    path: 'beast',
    label: '兽灵 · 兽魂',
    short: '兽灵',
    hubTitle: '兽灵 · 兽魂',
    hubCrumb: '兽灵 BEAST',
    hubSubtitle: '图鉴、词条、技能 —— 兽灵系统的三本账',
  ),
  job(
    path: 'job',
    label: '职业',
    short: '职业',
    hubTitle: '职业中心',
    hubCrumb: '职业 CLASS',
    hubSubtitle: '武道、技能、加点 —— 九大门派的修炼手册',
  );

  const ToolGroup({
    required this.path,
    required this.label,
    required this.short,
    required this.hubTitle,
    required this.hubCrumb,
    required this.hubSubtitle,
  });

  /// 路由段（也是首页分类 `data-cat`、URL 首段）。
  final String path;

  /// 分类短名：首页筛选 chip。
  final String label;

  /// 面包屑链接文本（如 宝宝 / 兽灵 / 职业）。
  final String short;

  /// hub 页标题 / 面包屑尾段。
  final String hubTitle;
  final String hubCrumb;
  final String hubSubtitle;

  /// hub 路由 location（与各 feature 的 hub 根路由路径一致）。
  String get hubLocation => '/$path';
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
    this.isHot = false,
  });

  /// 稳定 id（如 `pet-calc`），对应原型视图 `v-<id>` 后缀。
  final String id;

  /// 所属分组。
  final ToolGroup group;

  /// 统一标题（路由 name / 信息条 / 页头 h1 / 卡片名）。
  final String title;

  /// 工具页头面包屑，如 `宝宝 / 资质计算`。
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
  // ---- 宝宝 pet ----
  static const ToolDef petCalc = ToolDef(
    id: 'pet-calc',
    group: ToolGroup.pet,
    title: '宝宝资质计算',
    crumb: '宝宝 / 资质计算',
    pageSubtitle: '输入当前资质与悟灵状态，预估培养至目标悟灵后的成品资质、评级与成长空间',
    cardDesc: '成长率 × 悟性 × 灵性，预估成品资质与评级',
    keywords: ['资质', '计算', '宝宝', '成长率', '悟性', '灵性', '内功', '外功', '超灵'],
    location: '/pet/calc',
    icon: 'calc',
    isHot: true,
  );

  static const ToolDef petProb = ToolDef(
    id: 'pet-prob',
    group: ToolGroup.pet,
    title: '宝宝技能释放概率',
    crumb: '宝宝 / 技能概率',
    pageSubtitle: '按性格查看自动 / 状态 / 辅助技能的触发概率与判定方式',
    cardDesc: '自动 / 状态 / 辅助技能触发判定一览',
    keywords: ['技能', '概率', '释放', '触发', '判定', '猛击', '连击', '附身'],
    location: '/pet/prob',
    icon: 'pct',
  );

  static const ToolDef petSuit = ToolDef(
    id: 'pet-suit',
    group: ToolGroup.pet,
    title: '宝宝套装图鉴',
    crumb: '宝宝 / 套装图鉴',
    pageSubtitle: '六大性格套装的件数效果与适配宝宝类型',
    cardDesc: '六大性格套装件数效果与适配推荐',
    keywords: ['套装', '图鉴', '宝宝', '勇猛', '胆小', '谨慎', '精明', '忠诚', '内敛'],
    location: '/pet/suit',
    icon: 'shield',
  );

  // ---- 兽灵 · 兽魂 beast ----
  static const ToolDef beastSoul = ToolDef(
    id: 'beast-soul',
    group: ToolGroup.beast,
    title: '兽魂查询',
    crumb: '兽灵 / 兽魂查询',
    pageSubtitle: '按品质筛选兽魂，速查主副词条与综合评分',
    cardDesc: '主副词条 · 品质筛选 · 评分速查',
    keywords: ['兽魂', '词条', '评分', '品质', '火攻', '冰攻'],
    location: '/beast/soul',
    icon: 'flame',
  );

  static const ToolDef beastIndex = ToolDef(
    id: 'beast-index',
    group: ToolGroup.beast,
    title: '兽灵图鉴',
    crumb: '兽灵 / 图鉴',
    pageSubtitle: '收录兽灵的星级、属性流派与携带等级',
    cardDesc: '星级属性 · 携带等级 · 获取途径',
    keywords: ['兽灵', '图鉴', '星级', '内功', '外功', '平衡', '携带', '等级'],
    location: '/beast/index',
    icon: 'gem',
  );

  static const ToolDef beastSkill = ToolDef(
    id: 'beast-skill',
    group: ToolGroup.beast,
    title: '兽灵技能效果',
    crumb: '兽灵 / 技能效果',
    pageSubtitle: '点击展开 Lv.1-5 等级数值表',
    cardDesc: 'Lv.1-5 等级数值表 · 触发条件',
    keywords: ['兽灵', '技能', '等级', '效果', '数值', '冷却'],
    location: '/beast/skill',
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
    pageSubtitle: '九大门派专属神兵 · 简介 / 属性 / 获取途径 · 42-102 级',
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
    pageSubtitle: '九大门派背景 · 门派特色 · 属性倾向 · 适合人群',
    cardDesc: '背景 · 特色 · 属性倾向 · 适合人群',
    keywords: ['门派', '背景', '特色', '介绍', '属性', '适合'],
    location: '/job/sect',
    icon: 'shield',
  );

  /// 全部 11 个工具（首页网格顺序）。
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
  ];

  /// 某分组下的工具（hub 页列表顺序）。
  static List<ToolDef> ofGroup(ToolGroup group) =>
      all.where((t) => t.group == group).toList(growable: false);

  /// 首页顶部统计（演示值；正式接入后改为按数据仓库统计）。
  static const List<HomeStat> homeStats = [
    HomeStat(48, '兽灵图鉴'),
    HomeStat(216, '技能数据'),
    HomeStat(24, '套装收录'),
    HomeStat(9, '门派覆盖'),
  ];
}
