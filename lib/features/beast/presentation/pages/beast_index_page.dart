import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/beast_spirit.dart';

/// 兽灵图鉴（对应原型 `v-beast-index`）。
///
/// 流派（内功/外功/平衡）筛选 + 字徽卡片网格，点卡片打开
/// 「成长档位」分档弹窗（spiritModal）。
class BeastIndexPage extends StatefulWidget {
  const BeastIndexPage({super.key});

  @override
  State<BeastIndexPage> createState() => _BeastIndexPageState();
}

class _BeastIndexPageState extends State<BeastIndexPage> {
  /// 流派筛选（null = 全部）。
  BeastAttr? _attr;

  List<BeastSpirit> get _visible => _attr == null
      ? kBeastSpirits
      : kBeastSpirits.where((s) => s.attr == _attr).toList(growable: false);

  void _open(BeastSpirit spirit) {
    showTgModal(
      context: context,
      child: _SpiritDetailDialog(spirit: spirit),
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
                      crumbLeft: ToolCatalog.beastIndex.crumbRoot,
                      crumbTail: ToolCatalog.beastIndex.crumb.substring(
                        ToolCatalog.beastIndex.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.beastIndex.group.hubLocation),
                      title: ToolCatalog.beastIndex.title,
                      subtitle: ToolCatalog.beastIndex.pageSubtitle,
                    ),
                    // 流派筛选 chips
                    Wrap(
                      spacing: TgSpacing.s9,
                      runSpacing: TgSpacing.sm,
                      children: [
                        _AttrChip(
                          label: '全部',
                          active: _attr == null,
                          onTap: () => setState(() => _attr = null),
                        ),
                        for (final a in BeastAttr.values)
                          _AttrChip(
                            label: a.label,
                            active: _attr == a,
                            onTap: () => setState(() => _attr = a),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 卡片网格（≤640 固定 2 列；否则 auto-fill minmax(208,1fr)）
                    LayoutBuilder(
                      builder: (context, c) {
                        const minTile = 208.0;
                        const gap = 13.0;
                        final cols = compact
                            ? 2
                            : (((c.maxWidth + gap) / (minTile + gap)).floor())
                                  .clamp(2, 6);
                        final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final s in _visible)
                              SizedBox(
                                width: tileW,
                                child: _SpiritCard(
                                  spirit: s,
                                  onTap: () => _open(s),
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

/// 流派筛选 pill。
class _AttrChip extends StatefulWidget {
  const _AttrChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_AttrChip> createState() => _AttrChipState();
}

class _AttrChipState extends State<_AttrChip> {
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

/// 兽灵卡（`.spirit-card`）。
class _SpiritCard extends StatefulWidget {
  const _SpiritCard({required this.spirit, required this.onTap});

  final BeastSpirit spirit;
  final VoidCallback onTap;

  @override
  State<_SpiritCard> createState() => _SpiritCardState();
}

class _SpiritCardState extends State<_SpiritCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final s = widget.spirit;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _hover ? tg.card2 : tg.card,
          borderRadius: TgRadius.card,
          border: Border.all(color: _hover ? tg.borderHi : tg.border, width: 1),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                children: [
                  // sp-avatar：64 圆字徽
                  _Avatar(avatar: s.avatar, tone: s.tone),
                  const SizedBox(height: 12),
                  // sp-name：名字 + 稀有度 tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: tg.t1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      _RarityTag(spirit: s),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // stars
                  Text(
                    List.filled(s.stars, '★').join(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.5,
                      color: tg.gold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // sp-meta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 11),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: tg.border, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _metaLine(
                          context,
                          '属性 · ',
                          s.attr.label,
                          colored: s.isCommon
                              ? null
                              : _attrColor(context, s.attr),
                        ),
                        const SizedBox(height: 4),
                        _metaLine(context, '携带等级 · ', '${s.level}'),
                        const SizedBox(height: 4),
                        _metaLine(context, '定位 · ', s.role),
                      ],
                    ),
                  ),
                  // soul-more 底注
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: tg.borderHi, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '点击查看等级效果',
                          style: TextStyle(fontSize: 11.5, color: tg.t3),
                        ),
                        const Spacer(),
                        Text(
                          '最高 20 级 · 4 档',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: tg.gold2,
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

  Widget _metaLine(
    BuildContext context,
    String prefix,
    String value, {
    Color? colored,
  }) {
    final tg = context.tg;
    return Text.rich(
      TextSpan(
        text: prefix,
        style: TextStyle(fontSize: 11.5, color: tg.t3),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: colored ?? tg.t2,
            ),
          ),
        ],
      ),
    );
  }

  /// 卡片 meta 中「属性」按流派着色（普通灰色除外）。
  Color? _attrColor(BuildContext context, BeastAttr attr) {
    final tg = context.tg;
    return switch (attr) {
      BeastAttr.nei => tg.tagBlue,
      BeastAttr.wai => tg.tagRed,
      BeastAttr.bal => tg.gold2,
    };
  }
}

/// 64 圆字徽（径向渐变 + 描边）。
class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.tone});

  final String avatar;
  final BeastRarityTone tone;

  @override
  Widget build(BuildContext context) {
    final st = _toneStyle(tone);
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.45),
          colors: [st.glow, st.base.withValues(alpha: .05)],
        ),
        border: Border.all(color: st.border, width: 1),
      ),
      child: Text(
        avatar,
        style: TextStyle(
          fontFamily: TgFonts.serif,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: st.charText,
        ),
      ),
    );
  }
}

/// 稀有度 tag（`.tag tag-<rt>`）。
class _RarityTag extends StatelessWidget {
  const _RarityTag({required this.spirit});

  final BeastSpirit spirit;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final Color text;
    final Color border;
    final Color bg;
    switch (spirit.tone) {
      case BeastRarityTone.normal:
        text = tg.t2;
        border = tg.borderHi;
        bg = Colors.transparent;
      case BeastRarityTone.gold:
        text = tg.gold2;
        border = tg.goldTint(.4);
        bg = tg.goldTint(.08);
      case BeastRarityTone.blue:
        text = tg.tagBlue;
        border = tg.tagBorderOf(tg.blue);
        bg = tg.tintOf(tg.blue, .08);
      case BeastRarityTone.red:
        text = tg.tagRed;
        border = tg.tagBorderOf(tg.red);
        bg = tg.tintOf(tg.red, .08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        spirit.rarity,
        style: TextStyle(fontSize: 11, height: 1.7, color: text),
      ),
    );
  }
}

/// 稀有度 → 头像配色。
({Color base, Color border, Color charText, Color glow}) _toneStyle(
  BeastRarityTone tone,
) {
  switch (tone) {
    case BeastRarityTone.gold:
      return (
        base: const Color(0xFFE2B872),
        border: const Color(0x73E2B872),
        charText: const Color(0xFFF2D49B),
        glow: const Color(0x66E2B872),
      );
    case BeastRarityTone.blue:
      return (
        base: const Color(0xFF5B9BFF),
        border: const Color(0x735B9BFF),
        charText: const Color(0xFFBFDCFF),
        glow: const Color(0x665B9BFF),
      );
    case BeastRarityTone.red:
      return (
        base: const Color(0xFFFF7069),
        border: const Color(0x73FF7069),
        charText: const Color(0xFFFFC9C5),
        glow: const Color(0x66FF7069),
      );
    case BeastRarityTone.normal:
      return (
        base: const Color(0xFF94A3B8),
        border: const Color(0x6694A3B8),
        charText: const Color(0xFFCBD5E1),
        glow: const Color(0x4D94A3B8),
      );
  }
}

/// 成长档位弹窗（对应原型 spiritModal）。
class _SpiritDetailDialog extends StatefulWidget {
  const _SpiritDetailDialog({required this.spirit});

  final BeastSpirit spirit;

  @override
  State<_SpiritDetailDialog> createState() => _SpiritDetailDialogState();
}

class _SpiritDetailDialogState extends State<_SpiritDetailDialog> {
  int _tier = 0;

  BeastSpirit get _spirit => widget.spirit;
  BeastSpiritTier get _t => _spirit.tiers[_tier];

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final st = _toneStyle(_spirit.tone);
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 500;
        final seg = _SpSeg(
          labels: [for (final t in _spirit.tiers) t.lv],
          selected: _tier,
          onSelect: (i) => setState(() => _tier = i),
        );
        final head = Row(
          children: [
            // 字徽 tile 40
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.45),
                  colors: [st.glow, Colors.white.withValues(alpha: .03)],
                ),
                border: Border.all(color: st.border, width: 1),
              ),
              child: Text(
                _spirit.avatar,
                style: TextStyle(
                  fontFamily: TgFonts.serif,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: st.charText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _spirit.name,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: tg.t1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RarityTag(spirit: _spirit),
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
              seg,
            ] else ...[
              Row(
                children: [
                  Expanded(child: head),
                  const SizedBox(width: 12),
                  seg,
                ],
              ),
            ],
            const SizedBox(height: 14),
            // sp-meta：属性/携带等级/定位 + 星级
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 11),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tg.border, width: 1)),
              ),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      text: '属性 · ',
                      style: TextStyle(fontSize: 11.5, color: tg.t3),
                      children: [
                        TextSpan(
                          text: _spirit.attr.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: _spirit.isCommon
                                ? tg.t2
                                : switch (_spirit.attr) {
                                    BeastAttr.nei => tg.tagBlue,
                                    BeastAttr.wai => tg.tagRed,
                                    BeastAttr.bal => tg.gold2,
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: '携带等级 · ',
                      style: TextStyle(fontSize: 11.5, color: tg.t3),
                      children: [
                        TextSpan(
                          text: '${_spirit.level}',
                          style: TextStyle(fontSize: 11.5, color: tg.t2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: '定位 · ',
                      style: TextStyle(fontSize: 11.5, color: tg.t3),
                      children: [
                        TextSpan(
                          text: _spirit.role,
                          style: TextStyle(fontSize: 11.5, color: tg.t2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 星级（实星+空星，金色）
                  Text(
                    List.generate(
                      5,
                      (i) => i < _spirit.stars ? '★' : '☆',
                    ).join(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: tg.gold2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // 档位标题
            _SpSectionTitle(title: _t.title),
            const SizedBox(height: 10),
            // mats（成长·主 / 副）
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GrowthMatItem(badge: '主', name: '成长 · 主', value: _t.main),
                for (var i = 0; i < _t.subs.length; i++)
                  _GrowthMatItem(
                    badge: '${i + 1}',
                    name: '成长 · 副${i + 1}',
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
                    ..._fxSpans(
                      _t.fx,
                      TextStyle(fontSize: 12.5, height: 1.6, color: tg.t2),
                      tg,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11.5, color: tg.t3),
                children: [
                  const TextSpan(text: '※ 兽灵最高 '),
                  TextSpan(
                    text: '20 级',
                    style: TextStyle(fontSize: 11.5, color: tg.gold2),
                  ),
                  const TextSpan(text: '，共 4 个成长档位；升级保留已解锁效果。'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 解析 `<b>…</b>` → 金加粗。
  List<InlineSpan> _fxSpans(String raw, TextStyle base, TgColors tg) {
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

/// 成长材料条（`.mat-item`）。
class _GrowthMatItem extends StatelessWidget {
  const _GrowthMatItem({
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

/// 档位分段（`.lv-seg`）。
class _SpSeg extends StatelessWidget {
  const _SpSeg({
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tg.borderHi, width: 1),
      ),
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
                  // 原型 .lv-seg button.on：半透明金底 .14 + 内嵌 1px 金描边
                  color: i == selected ? tg.goldTint(.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.5),
                  border: i == selected
                      ? Border.all(color: tg.goldTint(.4), width: 1)
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

/// 小节标题（标题右侧分隔线）。
class _SpSectionTitle extends StatelessWidget {
  const _SpSectionTitle({required this.title});

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

/// 页脚。
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
