/// 天工阁设计令牌（Design Tokens）
/// 与《天工阁 · 设计规范 v1.0》一一对应：
/// 深色为基准主题，浅色为主题的暖纸面变体。
library;

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// 原始色值（raw tokens）
/// ---------------------------------------------------------------------------
abstract final class TgTokens {
  /// 按钮文字 / 金底上的墨色（两主题一致）
  static const Color btnInk = Color(0xFF1A1206);

  /// 渐变金：135° #F0CE8E → #C9995A（两主题一致）

  /// 深色主题
  static const Color dBg = Color(0xFF07090D);
  static const Color dPanel = Color(0xFF0C1016);
  static const Color dCard = Color(0xFF12161F);
  static const Color dCard2 = Color(0xFF171C28);
  static const Color dInset = Color(0xFF0D1119);
  static const Color dInset2 = Color(0xFF0E1219);
  static const Color dBorder = Color(0xFF1F2634);
  static const Color dBorderHi = Color(0xFF2B3547);
  static const Color dT1 = Color(0xFFECEFF5);
  static const Color dT2 = Color(0xFF9AA3B8);
  static const Color dT3 = Color(0xFF5D6678);
  static const Color dGold = Color(0xFFE2B872);
  static const Color dGold2 = Color(0xFFF2D49B);
  static const Color dGoldDp = Color(0xFFB98A45);
  static const Color dBlue = Color(0xFF5B9BFF);
  static const Color dGreen = Color(0xFF43D69A);
  static const Color dRed = Color(0xFFFF7069);
  static const Color dPurple = Color(0xFFA292FF);
  static const Color dCyan = Color(0xFF4FD1D9);
  static const Color dTagBlue = Color(0xFF8FBAFF);
  static const Color dTagGreen = Color(0xFF6FE0B4);
  static const Color dTagRed = Color(0xFFFF9C96);
  static const Color dTagPurple = Color(0xFFC3B8FF);
  static const Color dTagCyan = Color(0xFF7CE4EA);
  static const Color dSbThumb = Color(0xFF232B3A);

  /// 浅色主题
  static const Color lBg = Color(0xFFF4F3EE);
  static const Color lPanel = Color(0xFFFBFAF7);
  static const Color lCard = Color(0xFFFFFFFF);
  static const Color lCard2 = Color(0xFFF8F6F0);
  static const Color lInset = Color(0xFFEFECE3);
  static const Color lInset2 = Color(0xFFECE8DC);
  static const Color lBorder = Color(0xFFE8E4D9);
  static const Color lBorderHi = Color(0xFFD9D3C3);
  static const Color lT1 = Color(0xFF2A251D);
  static const Color lT2 = Color(0xFF6E675A);
  static const Color lT3 = Color(0xFFA29A8A);
  static const Color lGold = Color(0xFFA97D34);
  static const Color lGold2 = Color(0xFF8A6423);
  static const Color lGoldDp = Color(0xFF8A6423);
  static const Color lBlue = Color(0xFF3E7BE8);
  static const Color lGreen = Color(0xFF18A876);
  static const Color lRed = Color(0xFFDE5A52);
  static const Color lPurple = Color(0xFF7A66E0);
  static const Color lCyan = Color(0xFF1494A3);
  static const Color lTagBlue = Color(0xFF2F68D8);
  static const Color lTagGreen = Color(0xFF0E8A5F);
  static const Color lTagRed = Color(0xFFC04842);
  static const Color lTagPurple = Color(0xFF6A55C9);
  static const Color lTagCyan = Color(0xFF0F8492);
  static const Color lSbThumb = Color(0xFFCFC8B5);

  /// 渐变端点（两主题一致）
  static const Color gradGoldStart = Color(0xFFF0CE8E);
  static const Color gradGoldEnd = Color(0xFFC9995A);
}

/// ---------------------------------------------------------------------------
/// TgColors —— 全量色彩令牌挂载到 Theme
/// 用法：context.tg.gold / context.tg.card ...
/// ---------------------------------------------------------------------------
@immutable
class TgColors extends ThemeExtension<TgColors> {
  const TgColors({
    required this.brightness,
    required this.bg,
    required this.panel,
    required this.card,
    required this.card2,
    required this.inset,
    required this.inset2,
    required this.border,
    required this.borderHi,
    required this.t1,
    required this.t2,
    required this.t3,
    required this.gold,
    required this.gold2,
    required this.goldDp,
    required this.blue,
    required this.green,
    required this.red,
    required this.purple,
    required this.cyan,
    required this.tagBlue,
    required this.tagGreen,
    required this.tagRed,
    required this.tagPurple,
    required this.tagCyan,
    required this.sbThumb,
  });

  final Brightness brightness;
  final Color bg; // 页面底色
  final Color panel; // 侧栏 / 顶栏 / 底栏
  final Color card; // 卡片
  final Color card2; // 卡片内嵌块 / 图标底
  final Color inset; // 输入框 / 分段控件 / 注释条
  final Color inset2; // 表头 / 开关轨道 / 门派底
  final Color border; // 标准边框（1px）
  final Color borderHi; // 加强边框（交互件）
  final Color t1; // 主文字
  final Color t2; // 次级文字
  final Color t3; // 弱文字 / 注释
  final Color gold; // 品牌金（强调 / 激活 / 数字结果）
  final Color gold2; // 亮金（高亮文字 / 结果数字）
  final Color goldDp; // 深金（ornament / 选中底）
  final Color blue;
  final Color green;
  final Color red;
  final Color purple;
  final Color cyan;
  final Color tagBlue; // 标签文字色（深底提亮 / 浅底加深）
  final Color tagGreen;
  final Color tagRed;
  final Color tagPurple;
  final Color tagCyan;
  final Color sbThumb; // 滚动条

  static const TgColors dark = TgColors(
    brightness: Brightness.dark,
    bg: TgTokens.dBg,
    panel: TgTokens.dPanel,
    card: TgTokens.dCard,
    card2: TgTokens.dCard2,
    inset: TgTokens.dInset,
    inset2: TgTokens.dInset2,
    border: TgTokens.dBorder,
    borderHi: TgTokens.dBorderHi,
    t1: TgTokens.dT1,
    t2: TgTokens.dT2,
    t3: TgTokens.dT3,
    gold: TgTokens.dGold,
    gold2: TgTokens.dGold2,
    goldDp: TgTokens.dGoldDp,
    blue: TgTokens.dBlue,
    green: TgTokens.dGreen,
    red: TgTokens.dRed,
    purple: TgTokens.dPurple,
    cyan: TgTokens.dCyan,
    tagBlue: TgTokens.dTagBlue,
    tagGreen: TgTokens.dTagGreen,
    tagRed: TgTokens.dTagRed,
    tagPurple: TgTokens.dTagPurple,
    tagCyan: TgTokens.dTagCyan,
    sbThumb: TgTokens.dSbThumb,
  );

  static const TgColors light = TgColors(
    brightness: Brightness.light,
    bg: TgTokens.lBg,
    panel: TgTokens.lPanel,
    card: TgTokens.lCard,
    card2: TgTokens.lCard2,
    inset: TgTokens.lInset,
    inset2: TgTokens.lInset2,
    border: TgTokens.lBorder,
    borderHi: TgTokens.lBorderHi,
    t1: TgTokens.lT1,
    t2: TgTokens.lT2,
    t3: TgTokens.lT3,
    gold: TgTokens.lGold,
    gold2: TgTokens.lGold2,
    goldDp: TgTokens.lGoldDp,
    blue: TgTokens.lBlue,
    green: TgTokens.lGreen,
    red: TgTokens.lRed,
    purple: TgTokens.lPurple,
    cyan: TgTokens.lCyan,
    tagBlue: TgTokens.lTagBlue,
    tagGreen: TgTokens.lTagGreen,
    tagRed: TgTokens.lTagRed,
    tagPurple: TgTokens.lTagPurple,
    tagCyan: TgTokens.lTagCyan,
    sbThumb: TgTokens.lSbThumb,
  );

  /// 金色透明度阶：.06 注释底 / .08 tag底 / .10 激活底 / .14 开关选中 / .28 文字选中 / .35 描边 / .45 徽章描边
  Color goldTint(double opacity) => gold.withAlpha((255 * opacity).round());

  /// 通用语义色透明底（14% 常用于图标底 / 标签底）
  Color tintOf(Color base, double opacity) =>
      base.withAlpha((255 * opacity).round());

  /// 标签描边（主色 40%）
  Color tagBorderOf(Color base) => tintOf(base, .40);

  LinearGradient get gradGold => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [TgTokens.gradGoldStart, TgTokens.gradGoldEnd],
      );

  /// 页面辉光（bg 之上两个 radial glow）
  List<Color> get glows => brightness == Brightness.dark
      ? const [Color(0x13E2B872), Color(0x0D5B9BFF)] // .075 / .05
      : const [Color(0x1FA97D34), Color(0x123E7BE8)]; // .12 / .07

  Color get onErrorC =>
      brightness == Brightness.dark ? const Color(0xFF2A0D0A) : Colors.white;

  @override
  TgColors copyWith({
    Brightness? brightness,
    Color? bg,
    Color? panel,
    Color? card,
    Color? card2,
    Color? inset,
    Color? inset2,
    Color? border,
    Color? borderHi,
    Color? t1,
    Color? t2,
    Color? t3,
    Color? gold,
    Color? gold2,
    Color? goldDp,
    Color? blue,
    Color? green,
    Color? red,
    Color? purple,
    Color? cyan,
    Color? tagBlue,
    Color? tagGreen,
    Color? tagRed,
    Color? tagPurple,
    Color? tagCyan,
    Color? sbThumb,
  }) {
    return TgColors(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      panel: panel ?? this.panel,
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      inset: inset ?? this.inset,
      inset2: inset2 ?? this.inset2,
      border: border ?? this.border,
      borderHi: borderHi ?? this.borderHi,
      t1: t1 ?? this.t1,
      t2: t2 ?? this.t2,
      t3: t3 ?? this.t3,
      gold: gold ?? this.gold,
      gold2: gold2 ?? this.gold2,
      goldDp: goldDp ?? this.goldDp,
      blue: blue ?? this.blue,
      green: green ?? this.green,
      red: red ?? this.red,
      purple: purple ?? this.purple,
      cyan: cyan ?? this.cyan,
      tagBlue: tagBlue ?? this.tagBlue,
      tagGreen: tagGreen ?? this.tagGreen,
      tagRed: tagRed ?? this.tagRed,
      tagPurple: tagPurple ?? this.tagPurple,
      tagCyan: tagCyan ?? this.tagCyan,
      sbThumb: sbThumb ?? this.sbThumb,
    );
  }

  @override
  TgColors lerp(TgColors? other, double t) {
    if (other == null) return this;
    Color L(Color a, Color b) => Color.lerp(a, b, t)!;
    return TgColors(
      brightness: t < .5 ? brightness : other.brightness,
      bg: L(bg, other.bg),
      panel: L(panel, other.panel),
      card: L(card, other.card),
      card2: L(card2, other.card2),
      inset: L(inset, other.inset),
      inset2: L(inset2, other.inset2),
      border: L(border, other.border),
      borderHi: L(borderHi, other.borderHi),
      t1: L(t1, other.t1),
      t2: L(t2, other.t2),
      t3: L(t3, other.t3),
      gold: L(gold, other.gold),
      gold2: L(gold2, other.gold2),
      goldDp: L(goldDp, other.goldDp),
      blue: L(blue, other.blue),
      green: L(green, other.green),
      red: L(red, other.red),
      purple: L(purple, other.purple),
      cyan: L(cyan, other.cyan),
      tagBlue: L(tagBlue, other.tagBlue),
      tagGreen: L(tagGreen, other.tagGreen),
      tagRed: L(tagRed, other.tagRed),
      tagPurple: L(tagPurple, other.tagPurple),
      tagCyan: L(tagCyan, other.tagCyan),
      sbThumb: L(sbThumb, other.sbThumb),
    );
  }
}

/// 快捷读取：context.tg.gold
extension TgColorsContextX on BuildContext {
  TgColors get tg => Theme.of(this).extension<TgColors>()!;
}

/// ---------------------------------------------------------------------------
/// 字体
/// ---------------------------------------------------------------------------
abstract final class TgFonts {
  /// 正文无衬线：系统栈（Flutter 默认解析平台 CJK 字体）
  /// 如需与 Web 端完全一致，可在 pubspec 注册 Noto Sans SC 后改为：
  /// static const String sans = 'Noto Sans SC';
  static const String? sans = null;

  /// 标题衬线（品牌名 / 页面标题 / 大数字 / 徽章字）
  static const String serif = 'Noto Serif SC';
}

/// 17 级字号阶梯（px / 字重 / 用途见各注释）
abstract final class TgType {
  static const _tnum = [FontFeature.tabularFigures()];

  /// 42 / 700 结果大数字（res-num，移动端 36）
  static TextStyle numResult(Color c) => TextStyle(
      fontSize: 42, height: 1.1, fontWeight: FontWeight.w700,
      color: c, fontFeatures: _tnum);

  /// 38 / 600 hero 大标题（serif · 字距4 · 移动端30）
  static const TextStyle hero = TextStyle(
      fontFamily: TgFonts.serif, fontSize: 38, height: 1.25,
      fontWeight: FontWeight.w600, letterSpacing: 4);

  /// 30 / 600 hero 移动端
  static const TextStyle heroMobile = TextStyle(
      fontFamily: TgFonts.serif, fontSize: 30, height: 1.25,
      fontWeight: FontWeight.w600, letterSpacing: 3);

  /// 26 / 600 等级徽章字 / 大数字（serif）
  static const TextStyle display26 = TextStyle(
      fontFamily: TgFonts.serif, fontSize: 26, fontWeight: FontWeight.w600);

  /// 24 / 600 页面标题（serif · 字距1）
  static const TextStyle pageH1 = TextStyle(
      fontFamily: TgFonts.serif, fontSize: 24, height: 1.25,
      fontWeight: FontWeight.w600, letterSpacing: 1);

  /// 21 / 600 统计数字（tabular-nums）
  static TextStyle stat21(Color c) => TextStyle(
      fontSize: 21, fontWeight: FontWeight.w600, color: c,
      fontFeatures: _tnum);

  /// 19 / 600 品牌名 / 兽魂评分（serif · 字距2）
  static const TextStyle score19 = TextStyle(
      fontFamily: TgFonts.serif, fontSize: 19,
      fontWeight: FontWeight.w600, letterSpacing: 2);

  /// 17 / 500 顶栏标题（移动端 15）
  static const TextStyle topTitle =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: 1);

  /// 16 / 500 单元格数值
  static const TextStyle cell16 =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

  /// 15 / 500 步进器数字 / 操作按钮
  static const TextStyle control15 =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

  /// 14.5 / 500 卡片标题
  static const TextStyle cardTitle =
      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500);

  /// 14 / 400 正文 / 输入框
  static const TextStyle body14 = TextStyle(fontSize: 14, height: 1.65);

  /// 13.5 / 500 按钮 / 导航项
  static const TextStyle button =
      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500);

  /// 13 / 400 列表行 / 结果行
  static const TextStyle row13 =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  /// 12.5 / 400 表单 label / 小按钮
  static const TextStyle label =
      TextStyle(fontSize: 12.5, letterSpacing: .5);

  /// 12 / 400 面包屑 / 结果小注
  static const TextStyle caption = TextStyle(fontSize: 12);

  /// 11.5 / 400 注释 / 表头（字距1.5）
  static const TextStyle note =
      TextStyle(fontSize: 11.5, height: 1.7, letterSpacing: 1.5);

  /// 11 / 400 tag / 页脚
  static const TextStyle tag = TextStyle(fontSize: 11);

  /// 10.5 / 400 品牌副标 / 底栏文字
  static const TextStyle micro =
      TextStyle(fontSize: 10.5, letterSpacing: 1);

  /// 10 / 600 hot 角标（字距1）
  static const TextStyle hot =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1);
}

/// ---------------------------------------------------------------------------
/// 圆角（12 级）
/// ---------------------------------------------------------------------------
abstract final class TgRadius {
  static const double xs = 5; // hot 角标
  static const double sm = 6; // tag
  static const double s8 = 8; // 分段按钮 / focus
  static const double s9 = 9; // 步进器按钮
  static const double md = 10; // 导航项 / 小按钮 / 主题切换
  static const double lg = 11; // 主按钮 / 输入框 / seg / 品牌标
  static const double r12 = 12; // 图标底 tile / 结果块
  static const double r13 = 13; // 兽魂图标底
  static const double r14 = 14; // 等级徽章
  static const double xl = 16; // 卡片（--r）
  static const double pill = 999; // 胶囊 / chip / 开关
  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get input => BorderRadius.circular(lg);
  static BorderRadius get btn => BorderRadius.circular(lg);
  static const BorderRadius pillShape = BorderRadius.all(Radius.circular(pill));
}

/// ---------------------------------------------------------------------------
/// 间距（4px 基准）与页面结构
/// ---------------------------------------------------------------------------
abstract final class TgSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double s9 = 9; // chips 间距 / note 图标距
  static const double s10 = 10; // 步进器内距 / 结果行高
  static const double s11 = 11; // 导航项内距
  static const double s12 = 12; // 列表行内距
  static const double s13 = 13; // 列表行纵向
  static const double s14 = 14; // 卡片栅格间距
  static const double md = 16; // 组件块间距
  static const double s18 = 18; // split 双栏间距
  static const double lg = 20; // 表单行距 / 列表行水平
  static const double s22 = 22; // 卡片紧凑内距
  static const double xl = 24; // 表单卡 / 结果卡内距
  static const double s28 = 28; // 内容区纵向
  static const double s34 = 34; // 内容区水平 / hero 纵向

  /// 内容区：28 / 34 / 底部 90（PC），maxWidth 1180
  static const EdgeInsets pagePadding =
      EdgeInsets.fromLTRB(28, 28, 34, 90);
  static const double pageMaxWidth = 1180;

  /// 卡片内距（表单卡 / 结果卡 24，紧凑卡 22）
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets cardPaddingTight = EdgeInsets.all(22);

  /// 表单行间距
  static const EdgeInsets formRowGap = EdgeInsets.only(bottom: 20);

  /// 列表行：13 / 20
  static const EdgeInsets listRowPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 13);

  /// 顶栏：13 / 34
  static const EdgeInsets topbarPadding =
      EdgeInsets.symmetric(horizontal: 34, vertical: 13);

  /// hero：34 / 36（移动端 26 / 22）
  static const EdgeInsets heroPadding =
      EdgeInsets.symmetric(horizontal: 36, vertical: 34);
  static const EdgeInsets heroPaddingMobile =
      EdgeInsets.symmetric(horizontal: 22, vertical: 26);

  /// 工具卡栅格：min 300，间距 14
  static const double gridMinTile = 300;
  static const double gridGap = 14;

  /// 侧栏宽度
  static const double sidebarWidth = 236;

  /// 底栏高度（另加 safe-area）
  static const double tabbarHeight = 58;
}

/// ---------------------------------------------------------------------------
/// 阴影与光效（全站仅 3 处投影）
/// ---------------------------------------------------------------------------
abstract final class TgShadows {
  /// 主按钮：0 5 20 rgba(198,152,86,.30)
  static const List<BoxShadow> primaryButton = [
    BoxShadow(offset: Offset(0, 5), blurRadius: 20, color: Color(0x4DC69856)),
  ];

  /// 金色徽章：0 4 18 rgba(226,184,114,.28)
  static const List<BoxShadow> goldBadge = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 18, color: Color(0x47E2B872)),
  ];

  /// focus 环补光：0 0 0 3px rgba(226,184,114,.12)（与 2px 描边叠加）
  static const List<BoxShadow> focusRing = [
    BoxShadow(blurRadius: 0, spreadRadius: 3, color: Color(0x1FE2B872)),
  ];
}
