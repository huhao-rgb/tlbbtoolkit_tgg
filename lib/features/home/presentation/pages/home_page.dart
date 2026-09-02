import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tool_card.dart';

/// 首页（工具箱 tab 根页面）：天工阁 Hero + 搜索 + 分类筛选 + 工具网格。
///
/// 忠实于原型 `v-home`：
/// - Hero 卡（TLBB · 怀旧服 标签 / 天工阁标题 / 副标题 / 搜索框）
/// - 分类 chips（全部 / 宝宝 / 兽灵 · 兽魂 / 职业）
/// - 统计（兽灵图鉴 / 技能数据 / 套装收录 / 门派覆盖）
/// - 工具网格（数据来自共享目录 `ToolCatalog`，点击跳转对应工具）
///
/// 页面不含 Scaffold/AppBar（信息条与 tabbar 由 shell 提供）。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ToolGroup? _group; // null = 全部
  String _keyword = '';

  List<ToolDef> get _visibleTools {
    final kw = _keyword;
    return ToolCatalog.all.where((t) {
      final okGroup = _group == null || t.group == _group;
      final okKw = kw.isEmpty ||
          t.title.contains(kw) ||
          t.keywords.any((k) => k.contains(kw));
      return okGroup && okKw;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return SingleChildScrollView(
          padding: compact
              ? const EdgeInsets.fromLTRB(
                  16, 20 + Breakpoints.topbarOverlayHeight, 16, 48)
              : TgSpacing.pagePadding.copyWith(
                  top: TgSpacing.pagePadding.top +
                      Breakpoints.topbarOverlayHeight, // 预留悬浮顶栏
                ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    compact: compact,
                    onSearch: (kw) => setState(() => _keyword = kw),
                  ),
                  const SizedBox(height: TgSpacing.s22),
                  _Toolbar(
                    selected: _group,
                    onSelect: (g) => setState(() => _group = g),
                  ),
                  const SizedBox(height: TgSpacing.s22),
                  _ToolGrid(tools: _visibleTools),
                  const SizedBox(height: TgSpacing.s34),
                  const _PageFoot(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hero 卡渐变（对应原型 CSS 变量，深/浅两套）：
/// - 背景 `--hero-a/b/c`：135° 三色；
/// - 标题文字 `--ht-a/b/c`：金色渐变（background-clip:text）。
const _heroGradientDark = [
  Color(0xFF141A26),
  Color(0xFF0F131B),
  Color(0xFF0E1118),
];
const _heroGradientLight = [
  Color(0xFFFFFFFF),
  Color(0xFFFBF9F3),
  Color(0xFFF7F4EA),
];
const _heroTitleGradientDark = [
  Color(0xFFF6E3B4),
  Color(0xFFE2B872),
  Color(0xFFB98A45),
];
const _heroTitleGradientLight = [
  Color(0xFFC09A55),
  Color(0xFF8A6423),
  Color(0xFF6E4E1D),
];

/// Hero 卡：渐变底 + 装饰大字 + TLBB 标签 + 渐变标题 + 副标题 + 搜索框。
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.compact, required this.onSearch});

  final bool compact;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;
    final heroGradient =
        isDark ? _heroGradientDark : _heroGradientLight;
    final titleGradient =
        isDark ? _heroTitleGradientDark : _heroTitleGradientLight;

    // 装饰大字：金色 230/170 serif · 低透明度（浅色略升）
    final decoColor = tg.gold.withValues(
      alpha: isDark ? .045 : .07,
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .6, 1],
          colors: heroGradient,
        ),
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Stack(
        children: [
          // 装饰大字（右上，衬在文字后面）
          Positioned(
            right: compact ? -8 : -14,
            top: compact ? -34 : -58,
            child: Text(
              '天',
              style: TextStyle(
                fontFamily: TgFonts.serif,
                fontSize: compact ? 170 : 230,
                fontWeight: FontWeight.w500,
                color: decoColor,
                height: 1,
              ),
            ),
          ),
          Padding(
            padding:
                compact ? TgSpacing.heroPaddingMobile : TgSpacing.heroPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TLBB · 怀旧服 标签（胶囊）
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? tg.goldTint(.07)
                          : const Color(0x1AA97D34), // 浅色金 10%
                      borderRadius: TgRadius.pillShape,
                      border: Border.all(
                        color: tg.goldTint(isDark ? .35 : .45),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'TLBB · 怀旧服',
                      style: TgType.tag.copyWith(
                        color: tg.gold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? TgSpacing.s12 : TgSpacing.md),
                  // 天工阁：金色渐变文字（background-clip:text）
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: titleGradient,
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      '天工阁',
                      style: (compact ? TgType.heroMobile : TgType.hero)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: compact ? TgSpacing.xs : TgSpacing.sm),
                  Text(
                    '资质计算 · 兽灵图鉴 · 武道加点 —— 九大工具，数据随身，行囊减半',
                    style: TgType.body14.copyWith(color: tg.t2),
                  ),
                  const SizedBox(height: TgSpacing.lg),
                  // 搜索框（按原型 .hero-search 还原：放大镜 left:13/宽17，文字从 39 起）
                  _HeroSearchField(
                    onSearch: onSearch,
                    isDark: isDark,
                    maxWidth: 430,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero 搜索框（对应原型 `.hero-search`）：
/// h44 · r11 · 半透明底（透出渐变）· 放大镜 left:13 宽17 · 文字从 39px 起（gap 9）。
class _HeroSearchField extends StatefulWidget {
  const _HeroSearchField({
    required this.onSearch,
    required this.isDark,
    this.maxWidth,
  });

  final ValueChanged<String> onSearch;
  final bool isDark;

  /// 与原型 `.hero-search{max-width:430px}` 对齐。
  final double? maxWidth;

  @override
  State<_HeroSearchField> createState() => _HeroSearchFieldState();
}

class _HeroSearchFieldState extends State<_HeroSearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final bg =
        widget.isDark ? const Color(0x8C07090D) : Colors.white; // rgba(7,9,13,.55)
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(TgRadius.lg),
            border: Border.all(
              color: _focused ? tg.goldTint(.55) : tg.border,
              width: 1,
            ),
            boxShadow: _focused ? TgShadows.focusRing : null,
          ),
          child: Row(
            children: [
              // 放大镜：left 13 · 17px
              const SizedBox(width: 13),
              TgIcon('search', size: 17, color: tg.t3),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  onChanged: widget.onSearch,
                  textInputAction: TextInputAction.search,
                  style: TgType.body14.copyWith(color: tg.t1),
                  cursorColor: tg.gold,
                  // 关键：清除主题 inputDecorationTheme 的默认（filled/边框/
                  // 最小高度/内距），否则会在外层自绘框里再渲染一层“输入框”。
                  decoration: InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    filled: false,
                    constraints: const BoxConstraints(),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: '搜索工具，如「资质」「武道」「兽魂」…',
                    hintStyle: TgType.body14.copyWith(color: tg.t3),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// 工具栏：分类 chips（左）+ 统计（右，窄屏换行）。
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.selected, required this.onSelect});

  final ToolGroup? selected;
  final ValueChanged<ToolGroup?> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final chips = <Widget>[
          _FilterChip(
            label: '全部',
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final g in ToolGroup.values)
            _FilterChip(
              label: g.label,
              active: selected == g,
              onTap: () => onSelect(g),
            ),
        ];

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                key: const Key('home-filter-chips'),
                spacing: TgSpacing.s9,
                runSpacing: TgSpacing.sm,
                children: chips,
              ),
              const SizedBox(height: TgSpacing.md),
              const _StatsRow(),
            ],
          );
        }
        return Row(
          children: [
            Wrap(
              key: const Key('home-filter-chips'),
              spacing: TgSpacing.s9,
              runSpacing: TgSpacing.sm,
              children: chips,
            ),
            const Spacer(),
            const _StatsRow(),
          ],
        );
      },
    );
  }
}

/// 分类筛选 chip（胶囊 · 选中金色提亮）。
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TgRadius.pillShape,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? tg.goldTint(.14) : tg.inset,
            borderRadius: TgRadius.pillShape,
            border: Border.all(
              color: active ? tg.goldTint(.5) : tg.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TgType.row13.copyWith(color: active ? tg.gold2 : tg.t2),
          ),
        ),
      ),
    );
  }
}

/// 统计：21/600 数字（tabular）+ 11.5 标签。
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ToolCatalog.homeStats.length; i++) ...[
          if (i != 0)
            Container(
              width: 1,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: tg.border,
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ToolCatalog.homeStats[i].value}',
                style: TgType.stat21(tg.gold2),
              ),
              Text(
                ToolCatalog.homeStats[i].label,
                style: TgType.note.copyWith(color: tg.t3),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 工具网格：按宽度自适应列数（min 300 · gap 14），窄屏单列。
class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.tools});

  final List<ToolDef> tools;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    if (tools.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Text(
          '未找到相关工具',
          style: TgType.body14.copyWith(color: tg.t3),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // 每项至少 300 宽（+14 gap），随可用宽度自适应列数。
        final gap = TgSpacing.gridGap;
        final cols = (((constraints.maxWidth + gap) /
                    (TgSpacing.gridMinTile + gap))
                .floor())
            .clamp(1, 4);
        final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tool in tools)
              SizedBox(width: tileWidth, child: ToolCard(tool: tool)),
          ],
        );
      },
    );
  }
}

/// 页脚（对应原型 `.page-foot`）。
class _PageFoot extends StatelessWidget {
  const _PageFoot();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Center(
      child: Column(
        children: [
          Container(width: 64, height: 1, color: tg.border),
          const SizedBox(height: TgSpacing.sm),
          Text(
            '天工阁 · 玩家自制工具集合，与畅游官方无关',
            textAlign: TextAlign.center,
            style: TgType.tag.copyWith(color: tg.t3),
          ),
          const SizedBox(height: 2),
          Text(
            '界面数据均为演示样例，正式版接入实战回归数值',
            textAlign: TextAlign.center,
            style: TgType.tag.copyWith(color: tg.t3),
          ),
        ],
      ),
    );
  }
}
