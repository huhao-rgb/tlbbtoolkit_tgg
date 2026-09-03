import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/pet_suit.dart';

/// 宝宝套装图鉴（对应原型 `v-pet-suit`）。
///
/// 视图 chips（套装图鉴 / 材料计算器）+ 主体：
/// - 图鉴：6 张套装卡（栅格），每卡独立档位（75/85/95）+ 件数效果 + 适配标签，
///   点击卡片弹出「五件套部件」弹窗；
/// - 材料计算器：档位 × 当前星级 × 含兑换材料 → 兑换 / 升星 / 合计消耗。
///
/// 数据与公式见 `pet_suit.dart`（与原型 `SUITS` / `SUIT_MATS` 一致）。
///
/// 页面不含 Scaffold/AppBar（信息条与返回按钮由 shell 框架提供）。
class PetSuitPage extends StatefulWidget {
  const PetSuitPage({super.key});

  @override
  State<PetSuitPage> createState() => _PetSuitPageState();
}

enum _SuitView { dex, calc }

class _PetSuitPageState extends State<PetSuitPage> {
  _SuitView _view = _SuitView.dex;

  /// 每张卡的独立档位（默认 85）。
  late final List<String> _cardLv = List.filled(kPetSuits.length, '85');

  // 材料计算器状态。
  String _calcLv = '85';
  int _calcStar = 0;
  bool _withExchange = true;

  void _openParts(int index) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xA807090D),
      builder: (_) => _SuitPartsDialog(
        suitIndex: index,
        initialLv: _cardLv[index],
        onLvChanged: (lv) {
          if (mounted) setState(() => _cardLv[index] = lv);
        },
      ),
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
                      crumbLeft: ToolCatalog.petSuit.crumbRoot,
                      crumbTail: ToolCatalog.petSuit.crumb
                          .substring(ToolCatalog.petSuit.crumbRoot.length),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.petSuit.group.hubLocation),
                      title: ToolCatalog.petSuit.title,
                      subtitle: ToolCatalog.petSuit.pageSubtitle,
                    ),
                    // 视图 chips
                    Wrap(
                      spacing: TgSpacing.s9,
                      runSpacing: TgSpacing.sm,
                      children: [
                        _SuitChip(
                          label: '套装图鉴',
                          active: _view == _SuitView.dex,
                          onTap: () => setState(() => _view = _SuitView.dex),
                        ),
                        _SuitChip(
                          label: '材料计算器',
                          active: _view == _SuitView.calc,
                          onTap: () =>
                              setState(() => _view = _SuitView.calc),
                        ),
                      ],
                    ),
                    const SizedBox(height: TgSpacing.md),
                    // 图鉴栅格
                    if (_view == _SuitView.dex)
                      _SuitGrid(
                        cardLv: _cardLv,
                        onCardTap: _openParts,
                        onLvChanged: (i, lv) =>
                            setState(() => _cardLv[i] = lv),
                      ),
                    // 材料计算器
                    if (_view == _SuitView.calc)
                      _CalcCard(
                        lv: _calcLv,
                        star: _calcStar,
                        withExchange: _withExchange,
                        onLvChanged: (lv) => setState(() => _calcLv = lv),
                        onStarChanged: (s) => setState(() => _calcStar = s),
                        onExchangeChanged: (v) =>
                            setState(() => _withExchange = v),
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

/// 视图切换 chip（胶囊 · 选中金色提亮）。
class _SuitChip extends StatelessWidget {
  const _SuitChip({
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

/// 套装图鉴栅格（对应 `.suit-grid`：auto-fill minmax 330 / gap 14）。
class _SuitGrid extends StatelessWidget {
  const _SuitGrid({
    required this.cardLv,
    required this.onCardTap,
    required this.onLvChanged,
  });

  final List<String> cardLv;
  final void Function(int index) onCardTap;
  final void Function(int index, String lv) onLvChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        const cardMin = 330.0;
        final cols = ((constraints.maxWidth + gap) / (cardMin + gap))
            .floor()
            .clamp(1, 3);
        final itemWidth =
            (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < kPetSuits.length; i++)
              SizedBox(
                width: itemWidth,
                child: _SuitCard(
                  suit: kPetSuits[i],
                  lv: cardLv[i],
                  onTap: () => onCardTap(i),
                  onLvChanged: (lv) => onLvChanged(i, lv),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 单张套装卡（`.suit-card`）：图标 + 名称/分类 + 档位 seg + 效果 + 适配 + 底部提示。
class _SuitCard extends StatelessWidget {
  const _SuitCard({
    required this.suit,
    required this.lv,
    required this.onTap,
    required this.onLvChanged,
  });

  final PetSuit suit;
  final String lv;
  final VoidCallback onTap;
  final ValueChanged<String> onLvChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TgRadius.card,
        child: Ink(
          padding: const EdgeInsets.all(TgSpacing.lg),
          decoration: BoxDecoration(
            color: tg.card,
            borderRadius: TgRadius.card,
            border: Border.all(color: tg.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // suit-top：tile + 名称/分类 + 档位 seg
              Row(
                children: [
                  _SuitTile(icon: suit.icon),
                  const SizedBox(width: TgSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suit.name,
                          style: TgType.control15.copyWith(
                            fontFamily: TgFonts.serif,
                            color: tg.t1,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _CatTag(text: suit.cat, color: suit.catColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: TgSpacing.sm),
                  _Seg(
                    values: kSuitLvKeys,
                    selected: lv,
                    onSelect: onLvChanged,
                  ),
                ],
              ),
              const SizedBox(height: TgSpacing.s14),
              // suit-effect
              Column(
                children: [
                  for (final e in suit.levels[lv] ?? const <PetSuitEffect>[])
                    _EffectRow(effect: e),
                ],
              ),
              // suit-fit
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: TgSpacing.s14),
                padding: const EdgeInsets.only(top: TgSpacing.s13),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0x4D2B3547), width: 1),
                  ),
                ),
                child: Wrap(
                  spacing: TgSpacing.xs,
                  runSpacing: TgSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '适配：',
                      style: TgType.caption.copyWith(color: tg.t3),
                    ),
                    for (final f in suit.fits) _NeutralTag(text: f),
                  ],
                ),
              ),
              // suit-more
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: TgSpacing.s14),
                padding: const EdgeInsets.only(top: TgSpacing.s12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0x4D2B3547), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '点击查看 5 件套部件',
                      style: TgType.caption.copyWith(color: tg.t3),
                    ),
                    const Spacer(),
                    Text(
                      '$lv 级档',
                      style: TgType.caption.copyWith(
                        color: tg.gold2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片图标底（`.tile`：44×44 · r12 · 金底）。
class _SuitTile extends StatelessWidget {
  const _SuitTile({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tg.goldTint(.10),
        borderRadius: BorderRadius.circular(TgRadius.r12),
        border: Border.all(color: tg.goldTint(.28), width: 1),
      ),
      child: TgIcon(icon, size: 21, color: tg.gold),
    );
  }
}

/// 分类 tag（`.tag-<catType>`）。
class _CatTag extends StatelessWidget {
  const _CatTag({required this.text, required this.color});

  final String text;
  final PetSuitCatColor color;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    Color textC;
    Color border;
    Color bg;
    switch (color) {
      case PetSuitCatColor.gold:
        textC = tg.gold2;
        border = tg.goldTint(.4);
        bg = tg.goldTint(.08);
      case PetSuitCatColor.cyan:
        textC = tg.tagCyan;
        border = tg.tagBorderOf(tg.cyan);
        bg = tg.tintOf(tg.cyan, .08);
      case PetSuitCatColor.green:
        textC = tg.tagGreen;
        border = tg.tagBorderOf(tg.green);
        bg = tg.tintOf(tg.green, .08);
      case PetSuitCatColor.blue:
        textC = tg.tagBlue;
        border = tg.tagBorderOf(tg.blue);
        bg = tg.tintOf(tg.blue, .08);
      case PetSuitCatColor.purple:
        textC = tg.tagPurple;
        border = tg.tagBorderOf(tg.purple);
        bg = tg.tintOf(tg.purple, .08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TgRadius.sm),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: TgType.tag.copyWith(color: textC, height: 1.7),
      ),
    );
  }
}

/// 适配标签（普通 tag，t2 / border-hi）。
class _NeutralTag extends StatelessWidget {
  const _NeutralTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TgRadius.sm),
        border: Border.all(color: tg.borderHi, width: 1),
      ),
      child: Text(
        text,
        style: TgType.tag.copyWith(color: tg.t2, height: 1.7),
      ),
    );
  }
}

/// 件数效果行（`.se-row`）：件数徽章 + 效果文案。
class _EffectRow extends StatelessWidget {
  const _EffectRow({required this.effect});

  final PetSuitEffect effect;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: tg.goldTint(.06),
              borderRadius: BorderRadius.circular(TgRadius.sm),
              border: Border.all(color: tg.goldTint(.3), width: 1),
            ),
            child: Text(
              effect.pieces,
              style: TgType.caption.copyWith(
                color: tg.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: TgSpacing.s10),
          Expanded(
            child: Text(
              effect.text,
              style: TgType.body14.copyWith(
                fontSize: 12.5,
                height: 1.6,
                color: tg.t2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分段控件（`.lv-seg`）：inset 底 + 按钮，选中金色提亮。
class _Seg extends StatelessWidget {
  const _Seg({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;

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
          for (final v in values)
            _SegBtn(
              label: v,
              active: v == selected,
              onTap: () => onSelect(v),
            ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
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
        borderRadius: BorderRadius.circular(6.5),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: active ? tg.goldTint(.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(6.5),
            border: active
                ? Border.all(color: tg.goldTint(.4), width: 1)
                : null,
          ),
          child: Text(
            label,
            style: TgType.caption.copyWith(
              color: active ? tg.gold2 : tg.t3,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 五件套部件预览弹窗（对应 `.modal` / `suitModal`）。
class _SuitPartsDialog extends StatefulWidget {
  const _SuitPartsDialog({
    required this.suitIndex,
    required this.initialLv,
    required this.onLvChanged,
  });

  final int suitIndex;
  final String initialLv;
  final ValueChanged<String> onLvChanged;

  @override
  State<_SuitPartsDialog> createState() => _SuitPartsDialogState();
}

class _SuitPartsDialogState extends State<_SuitPartsDialog> {
  late String _lv = widget.initialLv;

  PetSuit get _suit => kPetSuits[widget.suitIndex];

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final lvIndex = kSuitLvKeys.indexOf(_lv);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 0.84 * double.infinity),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tg.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tg.borderHi, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 70,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // modal-head
                LayoutBuilder(
                  builder: (context, c) {
                    final wrap = c.maxWidth < 420;
                    return wrap
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _SuitTile(icon: _suit.icon),
                                  const SizedBox(width: TgSpacing.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _suit.name,
                                          style: TgType.control15.copyWith(
                                            fontFamily: TgFonts.serif,
                                            color: tg.t1,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        _CatTag(
                                          text: _suit.cat,
                                          color: _suit.catColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _DialogClose(onTap: () => Navigator.pop(context)),
                                ],
                              ),
                              const SizedBox(height: TgSpacing.s12),
                              _Seg(
                                values: kSuitLvKeys,
                                selected: _lv,
                                onSelect: (lv) {
                                  setState(() => _lv = lv);
                                  widget.onLvChanged(lv);
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              _SuitTile(icon: _suit.icon),
                              const SizedBox(width: TgSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _suit.name,
                                      style: TgType.control15.copyWith(
                                        fontFamily: TgFonts.serif,
                                        color: tg.t1,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    _CatTag(
                                      text: _suit.cat,
                                      color: _suit.catColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: TgSpacing.sm),
                              _Seg(
                                values: kSuitLvKeys,
                                selected: _lv,
                                onSelect: (lv) {
                                  setState(() => _lv = lv);
                                  widget.onLvChanged(lv);
                                },
                              ),
                              const SizedBox(width: TgSpacing.s10),
                              _DialogClose(
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: TgSpacing.s14),
                // 件数效果
                Column(
                  children: [
                    for (final e
                        in _suit.levels[_lv] ?? const <PetSuitEffect>[])
                      _EffectRow(effect: e),
                  ],
                ),
                const SizedBox(height: TgSpacing.s14),
                // 五件套部件
                _SectionTitle(title: '五件套部件'),
                const SizedBox(height: TgSpacing.s10),
                Column(
                  children: [
                    for (final p in _suit.parts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PartRow(part: p, lvIndex: lvIndex),
                      ),
                  ],
                ),
                const SizedBox(height: TgSpacing.s14),
                // 适配
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: tg.goldTint(.07),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(10),
                    ),
                    border: Border(
                      left: BorderSide(color: tg.gold2, width: 3),
                    ),
                  ),
                  child: Wrap(
                    spacing: TgSpacing.xs,
                    runSpacing: TgSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '适配：',
                        style: TgType.caption.copyWith(color: tg.t2),
                      ),
                      for (final f in _suit.fits) _NeutralTag(text: f),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogClose extends StatelessWidget {
  const _DialogClose({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: tg.borderHi, width: 1),
          ),
          child: Center(
            child: TgIcon('x', size: 14, color: tg.t2),
          ),
        ),
      ),
    );
  }
}

/// 小节标题（`.mat-sec h4`：文字 + 分隔线）。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        Text(
          title,
          style: TgType.caption.copyWith(
            color: tg.t3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: TgSpacing.sm),
        Expanded(
          child: Container(height: 1, color: tg.borderHi),
        ),
      ],
    );
  }
}

/// 部件行（`.part-row`）：部位首字 + 名称/副词条 + 主属性。
class _PartRow extends StatelessWidget {
  const _PartRow({required this.part, required this.lvIndex});

  final PetSuitPart part;
  final int lvIndex;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tg.goldTint(.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: tg.goldTint(.28), width: 1),
            ),
            child: Text(
              part.slot.substring(0, 1),
              style: TgType.row13.copyWith(
                color: tg.gold2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: TgSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: TgType.row13.copyWith(
                    color: tg.t1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '副词条 · ${part.subAt(lvIndex)}',
                  style: TgType.caption.copyWith(color: tg.t3),
                ),
              ],
            ),
          ),
          const SizedBox(width: TgSpacing.s12),
          Text(
            part.attrAt(lvIndex),
            style: TgType.row13.copyWith(
              color: tg.gold2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 材料计算器卡（`.card` + `#suitCalc`）。
class _CalcCard extends StatelessWidget {
  const _CalcCard({
    required this.lv,
    required this.star,
    required this.withExchange,
    required this.onLvChanged,
    required this.onStarChanged,
    required this.onExchangeChanged,
  });

  final String lv;
  final int star;
  final bool withExchange;
  final ValueChanged<String> onLvChanged;
  final ValueChanged<int> onStarChanged;
  final ValueChanged<bool> onExchangeChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final result = suitMatsCalc(
      SuitMatCalcInput(
        lv: lv,
        currentStar: star,
        withExchange: withExchange,
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // calc-grid：档位 / 星级 / 含兑换材料
          Wrap(
            spacing: TgSpacing.sm,
            runSpacing: TgSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CalcLabel(text: '套装档位'),
              _Seg(values: kSuitLvKeys, selected: lv, onSelect: onLvChanged),
              const SizedBox(width: TgSpacing.s10),
              _CalcLabel(text: '当前星级'),
              _Seg(
                values: const ['0★', '1★', '2★', '3★', '4★'],
                selected: '$star★',
                onSelect: (s) =>
                    onStarChanged(int.parse(s.replaceAll('★', ''))),
              ),
              const SizedBox(width: TgSpacing.s10),
              _SuitChip(
                label: '含兑换材料',
                active: withExchange,
                onTap: () => onExchangeChanged(!withExchange),
              ),
            ],
          ),
          const SizedBox(height: TgSpacing.s18),
          // 兑换整套
          if (result.exchange.isNotEmpty) ...[
            _SectionTitle(title: '兑换 $lv 级套装 · 5 件'),
            const SizedBox(height: TgSpacing.s10),
            Wrap(
              spacing: TgSpacing.sm,
              runSpacing: TgSpacing.sm,
              children: [
                for (final m in result.exchange) _MatItem(item: m),
              ],
            ),
            const SizedBox(height: TgSpacing.s18),
          ],
          // 升星
          if (result.starRows.isNotEmpty) ...[
            _SectionTitle(title: '升星 $star★ → 5★ · $lv 级 · 5 件'),
            const SizedBox(height: TgSpacing.sm),
            for (final row in result.starRows) _StarLine(row: row),
            const SizedBox(height: TgSpacing.md),
          ],
          // 合计
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TgSpacing.md),
            decoration: BoxDecoration(
              color: tg.goldTint(.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tg.goldTint(.4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '合计消耗',
                  style: TgType.caption.copyWith(
                    color: tg.gold2,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: TgSpacing.s10),
                Wrap(
                  spacing: TgSpacing.sm,
                  runSpacing: TgSpacing.sm,
                  children: [
                    for (final m in result.total) _MatItem(item: m),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: TgSpacing.s14),
          Text(
            '※ 兑换材料为每部件消耗 ×5 件；升星第 k 星消耗 = 基础消耗 × k × 5 件。数据为 v1.4.0 参考值。',
            style: TgType.caption.copyWith(color: tg.t3),
          ),
        ],
      ),
    );
  }
}

class _CalcLabel extends StatelessWidget {
  const _CalcLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Text(
      text,
      style: TgType.label.copyWith(color: tg.t3),
    );
  }
}

/// 材料条目（`.mat-item`）：首字徽章 + 名称 + 数量。
class _MatItem extends StatelessWidget {
  const _MatItem({required this.item});

  final SuitMatItem item;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
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
              item.name.substring(0, 1),
              style: TgType.row13.copyWith(
                color: tg.gold2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: TgSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TgType.caption.copyWith(color: tg.t2),
              ),
              Text(
                '× ${suitFmtCount(item.count)}',
                style: TgType.row13.copyWith(
                  color: tg.t1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单星级升星行（`.star-line`）。
class _StarLine extends StatelessWidget {
  const _StarLine({required this.row});

  final SuitMatStarRow row;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final text = row.mats
        .map((m) => '${m.name} ×${suitFmtCount(m.count)}')
        .join('　·　');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row.star}★',
            style: TgType.row13.copyWith(
              color: tg.gold2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: TgSpacing.s10),
          Expanded(
            child: Text(
              text,
              style: TgType.caption.copyWith(
                color: tg.t2,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
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
