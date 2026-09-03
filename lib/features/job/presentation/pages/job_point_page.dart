import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/job_point.dart';
import '../../domain/job_sect.dart';
import '../widgets/job_mini_button.dart';
import '../widgets/job_sect_widgets.dart';

/// 职业加点计算器（对应原型 `v-class-point`）。
///
/// 门派 pills + 等级（10~119，默认 119）+ 五行潜能步进
/// （− 进度条 ＋，进度=已点/总潜能）+ 一键推荐 / 清空 +
/// 面板预览（气血/气/内外攻/命中/闪避，千分位）。
class JobPointPage extends StatefulWidget {
  const JobPointPage({super.key});

  @override
  State<JobPointPage> createState() => _JobPointPageState();
}

class _JobPointPageState extends State<JobPointPage> {
  /// 当前门派（默认逍遥，对应原型 `ptSect='xiaoyao'`）。
  JobSect _sect = kJobSects.firstWhere((s) => s.key == 'xiaoyao');

  /// 等级（默认 119）。
  int _lv = kPointLvMax;

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

  void _recommend() {
    setState(() {
      final rec = recommendPoints(_sect.key, _total);
      for (final a in kJobAttrs) {
        _pts[a.key] = rec[a.key] ?? 0;
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
                    16,
                    20 + Breakpoints.topbarOverlayHeight,
                    16,
                    48,
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
                    Container(
                      padding: const EdgeInsets.all(18),
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
                            onClear: _clear,
                          ),
                          const SizedBox(height: 4),
                          // 五行步进行
                          for (var i = 0; i < kJobAttrs.length; i++) ...[
                            if (i > 0) const SizedBox(height: 4),
                            _AttrRow(
                              def: kJobAttrs[i],
                              value: _pts[kJobAttrs[i].key]!,
                              ratio: _total == 0
                                  ? 0
                                  : _pts[kJobAttrs[i].key]! / _total,
                              canMinus: _pts[kJobAttrs[i].key]! > 0,
                              canPlus: _used < _total,
                              onMinus: () => _bump(kJobAttrs[i].key, -1),
                              onPlus: () => _bump(kJobAttrs[i].key, 1),
                            ),
                          ],
                          // 面板预览
                          const SizedBox(height: 16),
                          _PreviewSection(
                            sectName: _sect.name,
                            preview: computePreview(_lv, _pts),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '※ 每 1 级获得 5 点潜能（10 级起）；预览公式为参考基准，实际以游戏内为准。',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.tg.t3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TgSpacing.s34),
                    const _PageFoot(),
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

/// 顶部工具行：等级输入 + 剩余潜能 / 总 + 一键推荐 / 清空。
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.lv,
    required this.remain,
    required this.total,
    required this.onLv,
    required this.onRecommend,
    required this.onClear,
  });

  final bool compact;
  final int lv;
  final int remain;
  final int total;
  final ValueChanged<String> onLv;
  final VoidCallback onRecommend;
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
    final right = <Widget>[
      JobMiniButton(label: '一键推荐', onTap: onRecommend),
      const SizedBox(width: 8),
      JobMiniButton(label: '清空', onTap: onClear),
    ];
    if (!compact) {
      return Row(
        children: [
          for (var i = 0; i < left.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            left[i],
          ],
          const Spacer(),
          ...right,
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
        Row(mainAxisAlignment: MainAxisAlignment.end, children: right),
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
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

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
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: tg.t1,
                ),
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

/// 单条五行分配行（`-  bar  +  数值`）。
class _AttrRow extends StatelessWidget {
  const _AttrRow({
    required this.def,
    required this.value,
    required this.ratio,
    required this.canMinus,
    required this.canPlus,
    required this.onMinus,
    required this.onPlus,
  });

  final JobAttrDef def;
  final int value;
  final double ratio;
  final bool canMinus;
  final bool canPlus;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
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
          // bar：进度（flex:1，金色渐变填充）
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: tg.inset,
                borderRadius: BorderRadius.circular(99),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC9995A), Color(0xFFF2D49B)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
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

/// 面板预览（`.mat-sec` h4 + auto-fit 网格 6 项）。
class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.sectName, required this.preview});

  final String sectName;
  final JobPreview preview;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final cells = <(String, int)>[
      ('气血上限', preview.hp),
      ('气上限', preview.mp),
      ('内功攻击', preview.atkP),
      ('外功攻击', preview.atkW),
      ('命中', preview.hit),
      ('闪避', preview.dodge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // h4：标题 + 分隔线（::after）
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Text(
                '面板预览 · ',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tg.t3,
                ),
              ),
              Text(
                sectName,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tg.gold2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: tg.borderHi)),
            ],
          ),
        ),
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
                          Text(
                            name,
                            style: TextStyle(fontSize: 12, color: tg.t2),
                          ),
                          Text(
                            formatThousand(count),
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

/// 页脚（与其它二级页保持一致）。
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
        ],
      ),
    );
  }
}
