import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_card.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/beast_soul.dart';

/// 兽魂查询（对应原型 `v-beast-soul`）。
///
/// 类型 chips 筛选（神兽魂 / 荒兽魂 / 灵兽魂）+ 十五大兽魂卡片网格
/// （出战 / 融魂技能速查），点卡片打开「兽灵等级效果」弹窗（soulModal）：
/// 出战技能详情 + 融魂技能魂境 1–6 阶数值。
class BeastSoulPage extends StatefulWidget {
  const BeastSoulPage({super.key});

  @override
  State<BeastSoulPage> createState() => _BeastSoulPageState();
}

class _BeastSoulPageState extends State<BeastSoulPage> {
  /// 类型筛选（null = 全部）。
  BeastSoulType? _type;

  List<BeastSoul> get _visible => _type == null
      ? kBeastSouls
      : kBeastSouls.where((s) => s.type == _type).toList(growable: false);

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
                    TgSpacing.pagePaddingMobileH,
                    20 + Breakpoints.topbarOverlayHeight,
                    TgSpacing.pagePaddingMobileH,
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
                    // 类型筛选 chips
                    Wrap(
                      spacing: TgSpacing.s9,
                      runSpacing: TgSpacing.sm,
                      children: [
                        _SoulChip(
                          label: '全部',
                          active: _type == null,
                          onTap: () => setState(() => _type = null),
                        ),
                        for (final t in BeastSoulType.values)
                          _SoulChip(
                            label: t.label,
                            active: _type == t,
                            onTap: () => setState(() => _type = t),
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

/// 类型筛选 pill（对应原型 `.chip`）。
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

/// 兽魂卡（`.soul-card`：图标 + 名称/类型 + 出战｜融魂技能）。
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
            child: TgCardPadding(
              base: const EdgeInsets.all(TgSpacing.lg),
              child: Row(
                children: [
                  // soul-ico：46·r13，有图标用图片，无图标用类型配色首字
                  _SoulIco(soul: soul),
                  const SizedBox(width: TgSpacing.s13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // s-name：名称 + 类型 tag
                        Row(
                          children: [
                            Flexible(
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
                            _TypeTag(type: soul.type),
                          ],
                        ),
                        // s-sub：出战 · 技能名｜融魂 · 技能名
                        const SizedBox(height: 4),
                        Text(
                          '出战 · ${soul.cs.name}｜融魂 · ${soul.rh.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: tg.t2),
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

/// 兽魂图标（`.soul-ico` 46·r13）：有官网图标显示图片，无图标显示首字。
class _SoulIco extends StatelessWidget {
  const _SoulIco({required this.soul});

  final BeastSoul soul;

  @override
  Widget build(BuildContext context) {
    final a = _accent(context, soul.type);
    final icon = soul.cs.iconPath;
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: a.icoBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: a.icoBorder, width: 1),
      ),
      child: icon != null
          ? Image.asset(
              icon,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _CharTile(
                char: soul.name.characters.first,
                accent: a,
                fontSize: 20,
              ),
            )
          : _CharTile(
              char: soul.name.characters.first,
              accent: a,
              fontSize: 20,
            ),
    );
  }
}

/// 无图标时的首字占位（serif 首字 + 类型配色）。
class _CharTile extends StatelessWidget {
  const _CharTile({
    required this.char,
    required this.accent,
    required this.fontSize,
  });

  final String char;
  final _TypeAccent accent;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: accent.icoBg),
      child: Text(
        char,
        style: TextStyle(
          fontFamily: TgFonts.serif,
          fontSize: fontSize,
          height: 1,
          color: accent.icoFg,
        ),
      ),
    );
  }
}

/// 类型 tag（对应原型 `.q-<type>`，文案为类型全名）。
class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.type});

  final BeastSoulType type;

  @override
  Widget build(BuildContext context) {
    final a = _accent(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: a.tagBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: a.tagBorder, width: 1),
      ),
      child: Text(
        type.label,
        style: TextStyle(fontSize: 11, height: 1.7, color: a.tagText),
      ),
    );
  }
}

/// 类型 → 配色（神兽魂=金 / 荒兽魂=紫 / 灵兽魂=蓝，对应原型 `SOUL_QC`）。
typedef _TypeAccent = ({
  Color icoBg,
  Color icoBorder,
  Color icoFg,
  Color tagText,
  Color tagBg,
  Color tagBorder,
});

_TypeAccent _accent(BuildContext context, BeastSoulType type) {
  final tg = context.tg;
  switch (type) {
    case BeastSoulType.shen:
      return (
        icoBg: tg.goldTint(.12),
        icoBorder: tg.goldTint(.4),
        icoFg: tg.gold2,
        tagText: tg.gold2,
        tagBg: tg.goldTint(.10),
        tagBorder: tg.goldTint(.45),
      );
    case BeastSoulType.huang:
      return (
        icoBg: tg.tintOf(tg.purple, .12),
        icoBorder: tg.tagBorderOf(tg.purple),
        icoFg: tg.purple,
        tagText: tg.tagPurple,
        tagBg: tg.tintOf(tg.purple, .10),
        tagBorder: tg.tintOf(tg.purple, .45),
      );
    case BeastSoulType.ling:
      return (
        icoBg: tg.tintOf(tg.blue, .12),
        icoBorder: tg.tagBorderOf(tg.blue),
        icoFg: tg.blue,
        tagText: tg.tagBlue,
        tagBg: tg.tintOf(tg.blue, .10),
        tagBorder: tg.tintOf(tg.blue, .45),
      );
  }
}

/// 兽灵等级效果弹窗（对应原型 soulModal）。
///
/// 上半区「出战技能」：图标 + 技能名 + 主动/被动 tag + 完整描述；
/// 下半区「融魂技能」：魂境阶级 1–6 阶分段 + 该阶数值（未公布时显示
/// 官网暂未公布的说明）。
class _SoulDetailDialog extends StatefulWidget {
  const _SoulDetailDialog({required this.soul});

  final BeastSoul soul;

  @override
  State<_SoulDetailDialog> createState() => _SoulDetailDialogState();
}

class _SoulDetailDialogState extends State<_SoulDetailDialog> {
  /// 魂境阶级索引（默认 6 阶 = 末档，官方已公布）。
  int _rhTier = 5;

  BeastSoul get _soul => widget.soul;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final a = _accent(context, _soul.type);
    final head = Row(
      children: [
        // tile 40 · 类型配色（有图标显示图片）
        Container(
          width: 40,
          height: 40,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: a.icoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.icoBorder, width: 1),
          ),
          child: _soul.cs.iconPath != null
              ? Image.asset(
                  _soul.cs.iconPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      _CharTile(char: _soul.name.characters.first, accent: a, fontSize: 22),
                )
              : _CharTile(char: _soul.name.characters.first, accent: a, fontSize: 22),
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
              _TypeTag(type: _soul.type),
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
        head,
        const SizedBox(height: 18),
        // 出战技能
        const _SectionTitle(title: '出战技能'),
        const SizedBox(height: 10),
        _SkillMat(soul: _soul),
        const SizedBox(height: 14),
        // 融魂技能
        const _SectionTitle(title: '融魂技能'),
        const SizedBox(height: 10),
        _RhSeg(
          labels: [for (final t in _soul.rh.tiers) t.segLabel],
          selected: _rhTier,
          onSelect: (i) => setState(() => _rhTier = i),
        ),
        const SizedBox(height: 10),
        _RhBody(soul: _soul, tier: _soul.rh.tiers[_rhTier]),
        const SizedBox(height: 14),
        // calc-note
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 11.5, color: tg.t3),
            children: [
              const TextSpan(text: '※ 融魂技能数值随'),
              TextSpan(
                text: '魂境阶级',
                style: TextStyle(fontSize: 11.5, color: tg.gold2),
              ),
              const TextSpan(text: '（上限 6 阶）提升而增强；官网资料站与官方攻略站目前仅公布 6 阶（满阶）数值，1–5 阶数值官方暂未发布。（数据源：官网资料站「兽魂技能」、官网攻略站「融魂、技能和扩展属性」）'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 出战技能材质条（`.mat-item`：图标/战徽 + 技能名 + 主动/被动 + 描述）。
class _SkillMat extends StatelessWidget {
  const _SkillMat({required this.soul});

  final BeastSoul soul;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final cs = soul.cs;
    return _MatShell(
      icon: cs.iconPath,
      badge: '战',
      iconSize: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  cs.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tg.t2),
                ),
              ),
              const SizedBox(width: 6),
              _KindTag(passive: cs.isPassive),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cs.body,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: tg.t1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 融魂技能材质条（`.mat-item`：图标/魂徽 + 技能名 + 该阶数值；未公布时
/// 显示官网暂未公布的说明块）。
class _RhBody extends StatelessWidget {
  const _RhBody({required this.soul, required this.tier});

  final BeastSoul soul;
  final BeastSoulRhTier tier;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final d = tier.description;
    if (d == null || d.isEmpty) {
      // 官网暂未公布：虚线说明块
      return CustomPaint(
        painter: _DashedBorderPainter(color: tg.border, radius: 11),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12.5, height: 1.7, color: tg.t2),
              children: [
                const TextSpan(text: '官网资料站暂未公布'),
                TextSpan(
                  text: '魂境 ${tier.lv} 阶',
                  style: TextStyle(fontSize: 12.5, color: tg.gold2),
                ),
                const TextSpan(text: '的融魂数值；官方攻略站说明：融魂技能数值受魂境阶级影响，阶数越高，数值越高。'),
              ],
            ),
          ),
        ),
      );
    }
    // 官网已公布：图标/魂徽 + 技能名 + 数值（首处「2）」换行，对应原型）
    return _MatShell(
      icon: soul.rh.iconPath,
      badge: '魂',
      iconSize: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(soul.rh.name, style: TextStyle(fontSize: 12, color: tg.t2)),
          const SizedBox(height: 4),
          Text(
            d.replaceFirst('2）', '\n2）'),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.7,
              color: tg.t1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 材质条外壳（`.mat-item`：inset 底 · r11 · 描边；左侧图标/徽章 + 内容）。
class _MatShell extends StatelessWidget {
  const _MatShell({
    required this.icon,
    required this.badge,
    required this.iconSize,
    required this.child,
  });

  /// 官网图标资源路径；为 null 时显示 [badge] 徽章。
  final String? icon;
  final String badge;
  final double iconSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 8, right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                icon!,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    _Badge(text: badge),
              ),
            )
          else
            _Badge(text: badge),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 徽章（`.mat-badge` 28·r8：金底 + 金描边 + 金字）。
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tg.goldTint(.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tg.goldTint(.28), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tg.gold2,
        ),
      ),
    );
  }
}

/// 主动/被动 tag（被动=蓝 / 主动=金，对应原型 `kind(d)`）。
class _KindTag extends StatelessWidget {
  const _KindTag({required this.passive});

  final bool passive;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final base = passive ? tg.blue : tg.gold;
    final text = passive ? tg.tagBlue : tg.gold2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tg.tintOf(base, .08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tg.tintOf(base, .4), width: 1),
      ),
      child: Text(
        passive ? '被动' : '主动',
        style: TextStyle(fontSize: 10, height: 1.5, color: text),
      ),
    );
  }
}

/// 魂境阶级分段控件（`.lv-seg`，默认选中末档 6 阶）。
class _RhSeg extends StatelessWidget {
  const _RhSeg({
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
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (var i = 0; i < labels.length; i++)
            InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(6.5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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

/// 虚线圆角边框（对应原型 `border:1px dashed` 的「暂未公布」说明块）。
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, math.min(dist + _dash, metric.length)),
          paint,
        );
        dist += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
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
