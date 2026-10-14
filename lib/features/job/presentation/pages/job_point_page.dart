import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/page_head.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';
import 'package:tlbbtoolkit/features/job/domain/job_point.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect.dart';
import 'package:tlbbtoolkit/features/job/presentation/widgets/job_mini_button.dart';
import 'package:tlbbtoolkit/features/job/presentation/widgets/job_sect_widgets.dart';

/// 职业加点计算器（对应原型 `v-class-point`）。
///
/// 门派 pills + 等级（10~119，默认 119）+ 五行潜能滑块
/// （− 滑块 ＋，滑块上限 = 已点 + 剩余潜能）+ 一键推荐 / 全点体力 · 全点身法 / 清空 +
/// 面板预览（气血/气/内外攻/命中/闪避/会心，按门派成长系数换算）+
/// 门派成长系数 · 每点潜能换算表。
class JobPointPage extends StatefulWidget {
  const JobPointPage({super.key, this.initialSect});

  /// 初始门派 key（如 `shaolin`；来自门派介绍页「深入这个门派」跳转）。
  /// 为空时保持默认逍遥。
  final String? initialSect;

  @override
  State<JobPointPage> createState() => _JobPointPageState();
}

class _JobPointPageState extends State<JobPointPage> {
  /// 当前门派（默认逍遥，对应原型 `ptSect='xiaoyao'`；
  /// 可由 `initialSect` 覆盖，支持跨页定位门派）。
  late JobSect _sect;

  /// 等级（默认 119）。
  int _lv = kPointLvMax;

  @override
  void initState() {
    super.initState();
    final key = widget.initialSect;
    _sect = (key != null && kJobSects.any((s) => s.key == key))
        ? kJobSects.firstWhere((s) => s.key == key)
        : kJobSects.firstWhere((s) => s.key == 'xiaoyao');
  }

  /// 五维已分配潜能。
  final Map<String, int> _pts = {for (final a in kJobAttrs) a.key: 0};

  int get _total => totalPoints(_lv);

  int get _used => _pts.values.fold(0, (a, b) => a + b);

  void _setLv(String raw) {
    final v = int.tryParse(raw.trim());
    setState(() => _lv = v ?? kPointLvMin);
  }

  void _bump(String key, int delta) {
    if (delta > 0 && _used >= _total) return;
    setState(() {
      _pts[key] = (_pts[key]! + delta).clamp(0, _total);
    });
  }

  /// 滑块直接赋值：上限为「总潜能 − 其他维度已用」，保证总和不超过总潜能。
  void _setPts(String key, int value) {
    final max = _total - (_used - _pts[key]!);
    setState(() => _pts[key] = value.clamp(0, max));
  }

  void _recommend() {
    setState(() {
      final rec = recommendPoints(_sect.key, _total);
      for (final a in kJobAttrs) {
        _pts[a.key] = rec[a.key] ?? 0;
      }
    });
  }

  /// 全点某一个维度：该维度吃满总潜能，其余清零。
  void _allTo(String key) {
    setState(() {
      for (final a in kJobAttrs) {
        _pts[a.key] = a.key == key ? _total : 0;
      }
    });
  }

  void _clear() {
    setState(() {
      for (final a in kJobAttrs) {
        _pts[a.key] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return TgPageEntrance(
          child: SingleChildScrollView(
            padding: compact
                ? const EdgeInsets.fromLTRB(
                    TgSpacing.pagePaddingMobileH,
                    20 + Breakpoints.topbarOverlayHeight,
                    TgSpacing.pagePaddingMobileH,
                    48 + Breakpoints.tabbarOverlayHeight, // 预留悬浮底栏
                  )
                : TgSpacing.pagePadding.copyWith(
                    top:
                        TgSpacing.pagePadding.top +
                        Breakpoints.topbarOverlayHeight, // 预留悬浮顶栏
                  ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TgPageHead(
                      crumbLeft: ToolCatalog.jobPoint.crumbRoot,
                      crumbTail: ToolCatalog.jobPoint.crumb.substring(
                        ToolCatalog.jobPoint.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.jobPoint.group.hubLocation),
                      title: ToolCatalog.jobPoint.title,
                      subtitle: ToolCatalog.jobPoint.pageSubtitle,
                    ),
                    // 门派筛选 pills（sect-row）
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        for (final s in kJobSects)
                          JobSectPill(
                            sect: s,
                            active: s.key == _sect.key,
                            onTap: () => setState(() => _sect = s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 计算卡片（padding 18）
                    TgCard(
                      basePadding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.tg.card,
                        borderRadius: TgRadius.card,
                        border: Border.all(color: context.tg.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 顶部：等级 · 剩余潜能 / 总 · 操作按钮
                          _TopBar(
                            compact: compact,
                            lv: _lv,
                            remain: _total - _used,
                            total: _total,
                            onLv: _setLv,
                            onRecommend: _recommend,
                            onAllTo: _allTo,
                            onClear: _clear,
                          ),
                          const SizedBox(height: 4),
                          // 五行步进行
                          for (var i = 0; i < kJobAttrs.length; i++) ...[
                            if (i > 0) const SizedBox(height: 4),
                            _AttrRow(
                              def: kJobAttrs[i],
                              value: _pts[kJobAttrs[i].key]!,
                              // 滑块上限 = 已点 + 剩余潜能，拖动不会超出总潜能
                              maxValue:
                                  _total - (_used - _pts[kJobAttrs[i].key]!),
                              canMinus: _pts[kJobAttrs[i].key]! > 0,
                              canPlus: _used < _total,
                              onMinus: () => _bump(kJobAttrs[i].key, -1),
                              onPlus: () => _bump(kJobAttrs[i].key, 1),
                              onChanged: (v) => _setPts(kJobAttrs[i].key, v),
                            ),
                          ],
                          // 面板预览
                          const SizedBox(height: 16),
                          _PreviewSection(
                            sectName: _sect.name,
                            preview: computePreview(_sect.key, _lv, _pts),
                          ),
                          // 门派成长系数 · 每点潜能换算
                          const SizedBox(height: 14),
                          _GrowthSection(sectKey: _sect.key),
                          const SizedBox(height: 12),
                          Text(
                            '※ 每 1 级获得 5 点潜能（10 级起）；加点增量按各门派成长系数计算'
                            '（玩家社区实测整理，≈ 为近似值，官方未公布完整成长表），'
                            '等级基线为通用近似，实际以游戏内为准。',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.tg.t3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TgSpacing.s34),
                    const TgPageFoot(text: '天工阁 · 玩家自制工具集合，与畅游官方无关'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 顶部工具行：等级输入 + 剩余潜能 / 总 + 一键推荐 / 全点体力 / 全点身法 / 清空。
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.lv,
    required this.remain,
    required this.total,
    required this.onLv,
    required this.onRecommend,
    required this.onAllTo,
    required this.onClear,
  });

  final bool compact;
  final int lv;
  final int remain;
  final int total;
  final ValueChanged<String> onLv;
  final VoidCallback onRecommend;

  /// 全点回调（参数为五维 key，如 `ti` / `shen`）。
  final ValueChanged<String> onAllTo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    // 与输入框文字同高（height 1.4），保证视觉垂直居中对齐
    final labelStyle = TextStyle(fontSize: 12.5, height: 1.4, color: tg.t2);
    final numStyle = TextStyle(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final left = <Widget>[
      Text('等级', style: labelStyle),
      // 数字输入（宽 76 · inset 底 · r8）
      SizedBox(
        width: 76,
        height: 32,
        child: _NumberField(value: lv, onChanged: onLv),
      ),
      Text('剩余潜能', style: labelStyle),
      Text('$remain', style: numStyle.copyWith(color: tg.gold2)),
      Text('/ 总', style: labelStyle.copyWith(color: tg.t3)),
      Text('$total', style: numStyle.copyWith(color: tg.t1)),
    ];
    // Wrap 会传入最大宽度约束，而 JobMiniButton 内的 Material 会撑满该宽度，
    // 故用 IntrinsicWidth 锁回内容宽度，使其在空间不足时能按需换行。
    final right = <Widget>[
      IntrinsicWidth(
        child: JobMiniButton(label: '一键推荐', onTap: onRecommend),
      ),
      IntrinsicWidth(
        child: JobMiniButton(label: '全点体力', onTap: () => onAllTo('ti')),
      ),
      IntrinsicWidth(
        child: JobMiniButton(label: '全点身法', onTap: () => onAllTo('shen')),
      ),
      IntrinsicWidth(
        child: JobMiniButton(label: '清空', onTap: onClear),
      ),
    ];
    if (!compact) {
      return Row(
        children: [
          for (var i = 0; i < left.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            left[i],
          ],
          const SizedBox(width: 12),
          // 按钮数较多，空间不足时换行而非溢出
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: right,
            ),
          ),
        ],
      );
    }
    // compact：上方潜能信息、按钮换行到下方
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < left.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              left[i],
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: right,
        ),
      ],
    );
  }
}

/// 等级数字输入框（可键盘输入，clamp 10~119）。
class _NumberField extends StatefulWidget {
  const _NumberField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<String> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.value}',
  );

  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: tg.inset,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focused ? tg.goldTint(.55) : tg.border,
            width: 1,
          ),
        ),
        // Row 包裹使文字垂直居中（避免定高容器内文字上偏）
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onSubmitted: (_) => widget.onChanged(_controller.text),
                style: TextStyle(fontSize: 13, height: 1.4, color: tg.t1),
                cursorColor: tg.gold,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单条五行分配行（`-  滑块  +  数值`）。
///
/// 滑块上限 [maxValue] = 已点 + 剩余潜能，拖动即不会超出总潜能；
/// 上限为 0（总潜能为 0）时滑块整行禁用。
class _AttrRow extends StatelessWidget {
  const _AttrRow({
    required this.def,
    required this.value,
    required this.maxValue,
    required this.canMinus,
    required this.canPlus,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
  });

  final JobAttrDef def;
  final int value;

  /// 该维度可分配上限（已点 + 剩余潜能）。
  final int maxValue;
  final bool canMinus;
  final bool canPlus;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  /// 滑块拖动回调（按 1 点离散取整后的目标值）。
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final enabled = maxValue > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.5, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          // p-lv：属性名（金 · 38px）
          SizedBox(
            width: 38,
            child: Text(
              def.label,
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1,
                color: tg.gold2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          JobMiniButton(label: '−', onTap: onMinus, enabled: canMinus),
          const SizedBox(width: 12),
          // slider：分配滑块（flex:1，金色轨道 · 1 点离散）
          Expanded(
            child: SizedBox(
              // 与 − / ＋ 按钮同高，行高保持原样
              height: 32,
              child: SliderTheme(
                data: _attrSliderTheme(tg),
                child: Slider(
                  value: (enabled ? value.clamp(0, maxValue) : 0).toDouble(),
                  // Slider 要求 min < max，禁用态用占位上限
                  max: enabled ? maxValue.toDouble() : 1.0,
                  divisions: enabled ? maxValue : null,
                  onChanged: enabled ? (v) => onChanged(v.round()) : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          JobMiniButton(label: '＋', onTap: onPlus, enabled: canPlus),
          const SizedBox(width: 10),
          // 值
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tg.gold2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 五行分配滑块的轨道配色（金轨 · inset 底轨 · r99），沿用原进度条观感。
SliderThemeData _attrSliderTheme(TgColors tg) {
  return SliderThemeData(
    trackHeight: 6,
    activeTrackColor: tg.gold,
    inactiveTrackColor: tg.inset,
    thumbColor: tg.gold2,
    overlayColor: tg.goldTint(.12),
    disabledActiveTrackColor: tg.borderHi,
    disabledInactiveTrackColor: tg.inset,
    disabledThumbColor: tg.borderHi,
    // 上限可达数百点，隐藏刻度与气泡（点数已由右侧数值显示）
    tickMarkShape: SliderTickMarkShape.noTickMark,
    showValueIndicator: ShowValueIndicator.never,
    trackShape: const RoundedRectSliderTrackShape(),
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 6.5,
      disabledThumbRadius: 6.5,
    ),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
  );
}

/// 面板预览（`.mat-sec` h4 + auto-fit 网格 7 项）。
class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.sectName, required this.preview});

  final String sectName;
  final JobPreview preview;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final cells = <(String, String)>[
      ('气血上限', formatGrouped(preview.hp)),
      ('气上限', formatGrouped(preview.mp)),
      ('内功攻击', formatFixed1(preview.atkP)),
      ('外功攻击', formatFixed1(preview.atkW)),
      ('命中', formatGrouped(preview.hit)),
      ('闪避', formatGrouped(preview.dodge)),
      ('会心攻击', formatCrit(preview.crit)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(title: '面板预览 · ', highlight: sectName),
        const SizedBox(height: 10),
        // auto-fit minmax(150px,1fr) 复刻
        LayoutBuilder(
          builder: (context, c) {
            const minTile = 150.0;
            const gap = 8.0;
            final cols = (((c.maxWidth + gap) / (minTile + gap)).floor()).clamp(
              1,
              cells.length,
            );
            final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (name, count) in cells)
                  SizedBox(
                    width: tileW,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tg.inset,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: tg.border, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: tg.t2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            count,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: tg.t1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 门派成长系数 · 每点潜能换算（`.pt-coef` auto-fill 网格 8 项）。
class _GrowthSection extends StatelessWidget {
  const _GrowthSection({required this.sectKey});

  final String sectKey;

  @override
  Widget build(BuildContext context) {
    final growth = jobGrowthOf(sectKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead(title: '门派成长系数 · 每点潜能换算'),
        const SizedBox(height: 10),
        // auto-fill minmax(168px,1fr) + gap 6 复刻
        LayoutBuilder(
          builder: (context, c) {
            const minTile = 168.0;
            const gap = 6.0;
            final cols = (((c.maxWidth + gap) / (minTile + gap)).floor()).clamp(
              1,
              kJobGrowthFields.length,
            );
            final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in kJobGrowthFields)
                  SizedBox(
                    width: tileW,
                    child: _GrowthTile(field: f, value: growth[f.key]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 单条成长系数（近似值整体弱化为 `t3` 并加 `≈` 前缀，对齐原型 `ptCoefHTML`）。
class _GrowthTile extends StatelessWidget {
  const _GrowthTile({required this.field, required this.value});

  final JobGrowthField field;
  final JobGrowthValue? value;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final approx = value?.approx ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              field.label,
              maxLines: 2,
              style: TextStyle(fontSize: 12, color: approx ? tg.t3 : tg.t2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value?.display ?? '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: approx ? tg.t3 : tg.t1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 小节标题（`.mat-sec h4`：标题 + 可选高亮 + 尾部细分隔线）。
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.highlight});

  final String title;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500);
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Text(title, style: style.copyWith(color: tg.t3)),
          if (highlight != null)
            Text(
              highlight!,
              style: style.copyWith(
                fontWeight: FontWeight.w600,
                color: tg.gold2,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: tg.borderHi)),
        ],
      ),
    );
  }
}
