import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/beast_soul.dart';

/// 兽魂查询（对应原型 `v-beast-soul`）。
///
/// 品质 chips 筛选 + 兽魂卡片网格（主/副词条 + 评分条），点卡片打开
/// 「等级效果」分档弹窗（soulModal）。
class BeastSoulPage extends StatefulWidget {
  const BeastSoulPage({super.key});

  @override
  State<BeastSoulPage> createState() => _BeastSoulPageState();
}

class _BeastSoulPageState extends State<BeastSoulPage> {
  /// 品质筛选（null = 全部）。
  BeastSoulQuality? _q;

  List<BeastSoul> get _visible => _q == null
      ? kBeastSouls
      : kBeastSouls.where((s) => s.quality == _q).toList(growable: false);

  void _open(int index) {
    showTgModal(
      context: context,
      child: _SoulDetailDialog(soul: kBeastSouls[index]),
    );
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
                      crumbLeft: ToolCatalog.beastSoul.crumbRoot,
                      crumbTail: ToolCatalog.beastSoul.crumb.substring(
                        ToolCatalog.beastSoul.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.beastSoul.group.hubLocation),
                      title: ToolCatalog.beastSoul.title,
                      subtitle: ToolCatalog.beastSoul.pageSubtitle,
                    ),
                    // 品质筛选 chips
                    Wrap(
                      spacing: TgSpacing.s9,
                      runSpacing: TgSpacing.sm,
                      children: [
                        _SoulChip(
                          label: '全部',
                          active: _q == null,
                          onTap: () => setState(() => _q = null),
                        ),
                        for (final q in BeastSoulQuality.values)
                          _SoulChip(
                            label: q.label,
                            active: _q == q,
                            onTap: () => setState(() => _q = q),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 卡片网格（auto-fill minmax(300,1fr) · gap14）
                    LayoutBuilder(
                      builder: (context, c) {
                        const minTile = 300.0;
                        const gap = 14.0;
                        final cols = ((c.maxWidth + gap) / (minTile + gap))
                            .floor()
                            .clamp(1, 4);
                        final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final s in _visible)
                              SizedBox(
                                width: tileW,
                                child: _SoulCard(
                                  soul: s,
                                  onTap: () => _open(kBeastSouls.indexOf(s)),
                                ),
                              ),
                          ],
                        );
                      },
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

/// 品质筛选 pill（对应原型 `.chip`）。
class _SoulChip extends StatefulWidget {
  const _SoulChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SoulChip> createState() => _SoulChipState();
}

class _SoulChipState extends State<_SoulChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final active = widget.active;
    final hover = _hover;
    final borderC = active
        ? tg.goldTint(.5)
        : (hover ? tg.goldTint(.45) : tg.borderHi);
    final textC = active ? tg.gold2 : (hover ? tg.t1 : tg.t2);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: TgRadius.pillShape,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6.5),
            decoration: BoxDecoration(
              color: active ? tg.goldTint(.10) : Colors.transparent,
              borderRadius: TgRadius.pillShape,
              border: Border.all(color: borderC, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: textC,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 兽魂卡（`.soul-card`）。
class _SoulCard extends StatefulWidget {
  const _SoulCard({required this.soul, required this.onTap});

  final BeastSoul soul;
  final VoidCallback onTap;

  @override
  State<_SoulCard> createState() => _SoulCardState();
}

class _SoulCardState extends State<_SoulCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final soul = widget.soul;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: _hover ? tg.card2 : tg.card,
          borderRadius: TgRadius.card,
          border: Border.all(
            color: _hover ? tg.goldTint(.32) : tg.border,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: TgRadius.card,
          child: InkWell(
            borderRadius: TgRadius.card,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(TgSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // soul-top：图标 + 名称/品质
                  Row(
                    children: [
                      _SoulIco(quality: soul.quality, icon: soul.icon),
                      const SizedBox(width: TgSpacing.s13),
                      Expanded(
                        child: Text(
                          soul.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tg.t1,
                          ),
                        ),
                      ),
                      const SizedBox(width: TgSpacing.s9),
                      _QualityTag(quality: soul.quality),
                    ],
                  ),
                  // soul-stat：主/副词条
                  const SizedBox(height: 15),
                  _StatLine(label: '主词条', value: soul.main),
                  const SizedBox(height: 8),
                  _StatLine(label: '副词条', value: soul.subs.join(' / ')),
                  // soul-score：评分 + 进度条
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 13),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: tg.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '评分',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: tg.t3,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          '${soul.score}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: tg.gold2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: tg.inset,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: soul.score / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFC9995A),
                                      Color(0xFFF2D49B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 主/副词条行：label · 值（值加粗 t1）。
class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Text.rich(
      TextSpan(
        text: '$label · ',
        style: TextStyle(fontSize: 12.5, color: tg.t2),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: tg.t1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 品质图标底（`.soul-ico` 46·r13，按品质配色）。
class _SoulIco extends StatelessWidget {
  const _SoulIco({required this.quality, required this.icon});

  final BeastSoulQuality quality;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final a = _accent(context, quality);
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: a.icoBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: a.icoBorder, width: 1),
      ),
      child: TgIcon(icon, size: 22, color: a.icoFg),
    );
  }
}

/// 品质 tag（`.q-<quality>`）。
class _QualityTag extends StatelessWidget {
  const _QualityTag({required this.quality});

  final BeastSoulQuality quality;

  @override
  Widget build(BuildContext context) {
    final a = _accent(context, quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: a.tagBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: a.tagBorder, width: 1),
      ),
      child: Text(
        quality.label,
        style: TextStyle(fontSize: 11, height: 1.7, color: a.tagText),
      ),
    );
  }
}

/// 品质 → 图标 / tag 配色（金用 gold2，其余图标用基础色、tag 用提亮色）。
({
  Color icoBg,
  Color icoBorder,
  Color icoFg,
  Color tagText,
  Color tagBg,
  Color tagBorder,
})
_accent(BuildContext context, BeastSoulQuality q) {
  final tg = context.tg;
  switch (q) {
    case BeastSoulQuality.gold:
      return (
        icoBg: tg.goldTint(.12),
        icoBorder: tg.goldTint(.4),
        icoFg: tg.gold2,
        tagText: tg.gold2,
        tagBg: tg.goldTint(.10),
        tagBorder: tg.goldTint(.45),
      );
    case BeastSoulQuality.purple:
      return (
        icoBg: tg.tintOf(tg.purple, .12),
        icoBorder: tg.tagBorderOf(tg.purple),
        icoFg: tg.purple,
        tagText: tg.tagPurple,
        tagBg: tg.tintOf(tg.purple, .10),
        tagBorder: tg.tintOf(tg.purple, .45),
      );
    case BeastSoulQuality.blue:
      return (
        icoBg: tg.tintOf(tg.blue, .12),
        icoBorder: tg.tagBorderOf(tg.blue),
        icoFg: tg.blue,
        tagText: tg.tagBlue,
        tagBg: tg.tintOf(tg.blue, .10),
        tagBorder: tg.tintOf(tg.blue, .45),
      );
    case BeastSoulQuality.green:
      return (
        icoBg: tg.tintOf(tg.green, .12),
        icoBorder: tg.tagBorderOf(tg.green),
        icoFg: tg.green,
        tagText: tg.tagGreen,
        tagBg: tg.tintOf(tg.green, .10),
        tagBorder: tg.tintOf(tg.green, .45),
      );
  }
}

/// 等级效果弹窗（对应原型 soulModal）。
class _SoulDetailDialog extends StatefulWidget {
  const _SoulDetailDialog({required this.soul});

  final BeastSoul soul;

  @override
  State<_SoulDetailDialog> createState() => _SoulDetailDialogState();
}

class _SoulDetailDialogState extends State<_SoulDetailDialog> {
  int _tier = 0;

  BeastSoul get _soul => widget.soul;
  BeastSoulTier get _t => _soul.tiers[_tier];

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final a = _accent(context, _soul.quality);
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 500;
        final seg = _Seg(
          labels: [for (final t in _soul.tiers) t.segLabel],
          selected: _tier,
          onSelect: (i) => setState(() => _tier = i),
        );
        final head = Row(
          children: [
            // tile 40 · 品质配色
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: a.icoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: a.icoBorder, width: 1),
              ),
              child: TgIcon(_soul.icon, size: 20, color: a.icoFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _soul.name,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: tg.t1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _QualityTag(quality: _soul.quality),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TgModalCloseButton(onTap: () => Navigator.pop(context)),
          ],
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow) ...[
              head,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: seg),
            ] else ...[
              Row(
                children: [
                  Expanded(child: head),
                  const SizedBox(width: 12),
                  seg,
                ],
              ),
            ],
            const SizedBox(height: 18),
            // 档位标题 + 分隔线
            _SectionTitle(title: _t.title),
            const SizedBox(height: 10),
            // 主/副词条 mats
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MatItem(badge: '主', name: '主词条', value: _t.main),
                for (var i = 0; i < _t.subs.length; i++)
                  _MatItem(
                    badge: '${i + 1}',
                    name: '副词条 ${i + 1}',
                    value: _t.subs[i],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // 档位特效
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tg.goldTint(.07),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
                border: Border(left: BorderSide(color: tg.gold2, width: 3)),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '档位特效 · ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tg.gold2,
                      ),
                    ),
                    ..._boldSpans(
                      _t.fx,
                      TextStyle(fontSize: 12.5, height: 1.6, color: tg.t2),
                      tg,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // calc-note
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11.5, color: tg.t3),
                children: [
                  const TextSpan(text: '※ 兽灵最高 '),
                  TextSpan(
                    text: '20 级',
                    style: TextStyle(fontSize: 11.5, color: tg.gold2),
                  ),
                  const TextSpan(text: '，共 4 个效果档位；升级保留已解锁效果。'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 解析 fx 里的 `<b>…</b>` → 金加粗。
  List<InlineSpan> _boldSpans(String raw, TextStyle base, TgColors tg) {
    final reg = RegExp(r'<b>(.*?)</b>');
    final out = <InlineSpan>[];
    var last = 0;
    for (final m in reg.allMatches(raw)) {
      if (m.start > last) {
        out.add(TextSpan(text: raw.substring(last, m.start), style: base));
      }
      out.add(
        TextSpan(
          text: m.group(1),
          style: base.copyWith(color: tg.gold2, fontWeight: FontWeight.w600),
        ),
      );
      last = m.end;
    }
    if (last < raw.length) {
      out.add(TextSpan(text: raw.substring(last), style: base));
    }
    return out;
  }
}

/// 材质条（`.mat-item`）：badge + 名称 + 数值。
class _MatItem extends StatelessWidget {
  const _MatItem({
    required this.badge,
    required this.name,
    required this.value,
  });

  final String badge;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tg.goldTint(.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tg.goldTint(.28), width: 1),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tg.gold2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: TextStyle(fontSize: 12, color: tg.t2)),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tg.t1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 档位分段控件（`.lv-seg`）。
class _Seg extends StatelessWidget {
  const _Seg({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tg.borderHi, width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(6.5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: i == selected ? tg.goldTint(.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.5),
                  boxShadow: i == selected
                      ? [
                          BoxShadow(
                            color: tg.goldTint(.4),
                            blurRadius: 0,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1,
                    fontWeight: i == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == selected ? tg.gold2 : tg.t3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 小节标题（标题右侧分隔细线，对应 `.mat-sec h4::after`）。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 12.5, color: tg.t3)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: tg.borderHi)),
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
