import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_card.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../../../shared/widgets/tg_segmented.dart';
import '../../domain/pet_suit.dart';

/// 宝宝套装图鉴（怀旧服珍兽套装 / 宝宝套）。
///
/// 视图 chips（套装图鉴 / 材料计算器）+ 主体：
/// - 图鉴：档位 chips（75 / 85 / 95，每档系列独立）+ 系列卡栅格
///   （类型 / 性格 / 全套效果 / 项圈出战效果），点击卡片弹出「五件套部件」弹窗；
/// - 材料计算器：档位 × 当前星级 × 含兑换材料 → 兑换 / 升星 / 合计消耗（单位：圣兽鳞）。
///
/// 数据与公式见 `pet_suit.dart`（22 个真实系列 + 圣兽鳞消耗表）。
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

  /// 图鉴档位（每档是一批独立系列，默认 85）。
  String _dexLv = '85';

  // 材料计算器状态（星级为「目标星级」，默认升满 5★）。
  String _calcLv = '85';
  int _calcStar = 5;
  bool _withExchange = true;

  void _openParts(PetSuitSeries series) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xA807090D),
      builder: (_) => _SuitPartsDialog(series: series),
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
                      crumbLeft: ToolCatalog.petSuit.crumbRoot,
                      crumbTail: ToolCatalog.petSuit.crumb.substring(
                        ToolCatalog.petSuit.crumbRoot.length,
                      ),
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
                          onTap: () => setState(() => _view = _SuitView.calc),
                        ),
                      ],
                    ),
                    const SizedBox(height: TgSpacing.md),
                    // 图鉴：档位切换 + 系列栅格 + 材料说明
                    if (_view == _SuitView.dex) ...[
                      _SuitLvRow(
                        lv: _dexLv,
                        onChanged: (lv) => setState(() => _dexLv = lv),
                      ),
                      const SizedBox(height: TgSpacing.md),
                      _SuitGrid(
                        series: petSuitsAt(_dexLv),
                        onCardTap: _openParts,
                      ),
                      const SizedBox(height: TgSpacing.s12),
                      Text(
                        '※ 珍兽套装每套 5 件，全套只用圣兽鳞一种材料：兑换 1★ 与升星均消耗圣兽鳞，'
                        '圣兽鳞由拆解珍兽套装获得（副本不直接掉落）。'
                        '兑换 / 升星 / 拆解均在苏州（248，184）云姗姗处，另有少量金钱消耗。',
                        style: TgType.caption.copyWith(
                          color: context.tg.t3,
                          height: 1.6,
                        ),
                      ),
                    ],
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

/// 档位切换行（75 / 85 / 95；每档系列独立，右侧显示系列数）。
class _SuitLvRow extends StatelessWidget {
  const _SuitLvRow({required this.lv, required this.onChanged});

  final String lv;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Wrap(
      spacing: TgSpacing.s9,
      runSpacing: TgSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _CalcLabel(text: '套装档位'),
        for (final k in kSuitLvKeys)
          _SuitChip(
            label: '$k 级套装',
            active: k == lv,
            onTap: () => onChanged(k),
          ),
        const SizedBox(width: TgSpacing.s10),
        Text(
          '共 ${petSuitsAt(lv).length} 个系列',
          style: TgType.caption.copyWith(color: tg.t3),
        ),
      ],
    );
  }
}

/// 套装图鉴栅格（对应 `.suit-grid`：auto-fill minmax 330 / gap 14）。
class _SuitGrid extends StatelessWidget {
  const _SuitGrid({required this.series, required this.onCardTap});

  final List<PetSuitSeries> series;
  final void Function(PetSuitSeries series) onCardTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        const cardMin = 330.0;
        final cols = ((constraints.maxWidth + gap) / (cardMin + gap))
            .floor()
            .clamp(1, 3);
        final itemWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in series)
              SizedBox(
                width: itemWidth,
                child: _SuitCard(suit: s, onTap: () => onCardTap(s)),
              ),
          ],
        );
      },
    );
  }
}

/// 单张套装卡（`.suit-card`）：图标 + 系列名 + 类型/性格 + 散件 / 全套 / 项圈效果 + 底部提示。
class _SuitCard extends StatefulWidget {
  const _SuitCard({required this.suit, required this.onTap});

  final PetSuitSeries suit;
  final VoidCallback onTap;

  @override
  State<_SuitCard> createState() => _SuitCardState();
}

class _SuitCardState extends State<_SuitCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final suit = widget.suit;
    // hover 与首页工具卡一致（200ms easeOut：上浮 -2 · 底 card2 · 描边泛金）
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // suit-top：tile + 系列名 + 类型/性格 tag
                  Row(
                    children: [
                      _SuitTile(icon: suit.icon),
                      const SizedBox(width: TgSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(suit.name, style: _suitNameStyle(tg)),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _CatTag(text: suit.type, color: suit.typeColor),
                                _NeutralTag(text: '${suit.personality}性格'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TgSpacing.s14),
                  // 散件属性方向（官方资料仅 75 档逐系列列出）
                  if (suit.stats.isNotEmpty) ...[
                    _InfoRow(label: '散件', text: suit.stats.join(' · ')),
                    const SizedBox(height: TgSpacing.s9),
                  ],
                  // 全套（穿齐 5 件）效果
                  _InfoRow(label: '全套', text: suit.fullEffect, accent: true),
                  if (suit.collar != null) ...[
                    const SizedBox(height: TgSpacing.s9),
                    _InfoRow(label: '项圈', text: '出战后${suit.collar!}'),
                  ],
                  // suit-more
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: TgSpacing.s14),
                    padding: const EdgeInsets.only(top: TgSpacing.s12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: tg.borderHi, width: 1),
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
                          '${suit.lv} 级档',
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
        ),
      ),
    );
  }
}

/// 部位图标资产名 → flutter_gen 资产（`assets/pet_suit/`）。
///
/// 目前 5 个图标是从官方装等图鉴截图中裁出的 40×40 小图（质量一般）；
/// 之后用游戏内截图替换时，只要保持同名同路径（建议 96×96 及以上的正方形 PNG，
/// 不带外框亦可 —— 渲染尺寸 34×34，`BoxFit.contain`）即可，无需改代码；
/// 若改了文件名，重跑 `fvm dart run build_runner build` 并更新本函数即可。
AssetGenImage _slotIcon(String name) => switch (name) {
  'part_claw' => Assets.petSuit.partClaw,
  'part_armor' => Assets.petSuit.partArmor,
  'part_ring' => Assets.petSuit.partRing,
  'part_charm' => Assets.petSuit.partCharm,
  _ => Assets.petSuit.partHelm,
};

/// 套装名称样式（原型 `.suit-name`：serif 15.5 · 600 · 字距1）。
TextStyle _suitNameStyle(TgColors tg) => TextStyle(
  fontFamily: TgFonts.serif,
  fontSize: 15.5,
  fontWeight: FontWeight.w600,
  letterSpacing: 1,
  color: tg.t1,
);

/// 图标底（`.tile`：卡内 44×44 · r12 金底；弹窗头传 size:40）。
class _SuitTile extends StatelessWidget {
  const _SuitTile({required this.icon, this.size = 44, this.iconSize = 21});

  final String icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tg.goldTint(.10),
        borderRadius: BorderRadius.circular(TgRadius.r12),
        border: Border.all(color: tg.goldTint(.28), width: 1),
      ),
      child: TgIcon(icon, size: iconSize, color: tg.gold),
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
      child: Text(text, style: TgType.tag.copyWith(color: textC, height: 1.7)),
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
      child: Text(text, style: TgType.tag.copyWith(color: tg.t2, height: 1.7)),
    );
  }
}

/// 效果行（label 徽章 + 文案）：散件属性 / 全套效果 / 项圈出战效果。
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.text,
    this.accent = false,
  });

  final String label;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: accent ? tg.goldTint(.06) : tg.inset,
            borderRadius: BorderRadius.circular(TgRadius.sm),
            border: Border.all(
              color: accent ? tg.goldTint(.3) : tg.borderHi,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TgType.caption.copyWith(
              color: accent ? tg.gold : tg.t3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: TgSpacing.s10),
        Expanded(
          child: Text(
            text,
            style: TgType.body14.copyWith(
              fontSize: 12.5,
              height: 1.6,
              color: accent ? tg.t1 : tg.t2,
            ),
          ),
        ),
      ],
    );
  }
}

/// 五件套部件预览弹窗（对应 `.modal` / `suitModal`）。
class _SuitPartsDialog extends StatelessWidget {
  const _SuitPartsDialog({required this.series});

  final PetSuitSeries series;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final cost = kSuitMatCost[series.lv]!;
    final perPieceFull = cost.perPieceTo(5);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
          maxHeight: 0.84 * double.infinity,
        ),
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
                // modal-head：tile + 系列名 + 档位/类型/性格 tag + 关闭
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SuitTile(icon: series.icon, size: 40, iconSize: 19),
                    const SizedBox(width: TgSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(series.name, style: _suitNameStyle(tg)),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _CatTag(
                                text: series.type,
                                color: series.typeColor,
                              ),
                              _NeutralTag(text: '${series.personality}性格'),
                              _NeutralTag(text: '${series.lv} 级档'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: TgSpacing.sm),
                    _DialogClose(onTap: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: TgSpacing.s14),
                // 五件套部件（项圈带系列专属出战效果）
                _SectionTitle(title: '五件套部件'),
                const SizedBox(height: TgSpacing.s10),
                Column(
                  children: [
                    for (final slot in kPetSuitSlots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PartRow(
                          slot: slot,
                          collar: slot.slot == '颈' ? series.collar : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: TgSpacing.s14),
                // 穿齐 5 件效果
                _SectionTitle(title: '穿齐 5 件效果'),
                const SizedBox(height: TgSpacing.s10),
                _InfoRow(label: '全套', text: series.fullEffect, accent: true),
                if (series.stats.isNotEmpty) ...[
                  const SizedBox(height: TgSpacing.s9),
                  _InfoRow(label: '散件', text: series.stats.join(' · ')),
                ],
                const SizedBox(height: TgSpacing.s14),
                // 圣兽鳞消耗
                _SectionTitle(title: '$kSuitMatName消耗 · ${series.lv} 级档'),
                const SizedBox(height: TgSpacing.s10),
                _CostLine(text: '兑换 1★（每件）', value: '${cost.exchange} 个'),
                _CostLine(
                  text: '升星 1★ → 5★（每件）',
                  value: '${cost.starUp.join(' / ')} 个',
                ),
                _CostLine(
                  text: '兑换 + 升满 5★（每件）',
                  value: '$perPieceFull 个',
                ),
                _CostLine(
                  text: '兑换 + 升满 5★（一套 5 件）',
                  value: '${perPieceFull * 5} 个',
                  accent: true,
                ),
                _CostLine(
                  text: '拆解返还（每件 1★~5★）',
                  value: cost.salvage.join(' / '),
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
                    border: Border(left: BorderSide(color: tg.gold2, width: 3)),
                  ),
                  child: Wrap(
                    spacing: TgSpacing.xs,
                    runSpacing: TgSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('适配：', style: TgType.caption.copyWith(color: tg.t2)),
                      _NeutralTag(text: series.fitText),
                    ],
                  ),
                ),
                const SizedBox(height: TgSpacing.s10),
                Text(
                  '※ 星级越高，散件数值、资质契合度与全套效果越好；5★ 为怀旧服上限。'
                  '圣兽鳞由拆解珍兽套装获得，副本不直接掉落。',
                  style: TgType.caption.copyWith(color: tg.t3, height: 1.6),
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
          child: Center(child: TgIcon('x', size: 14, color: tg.t2)),
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
        Expanded(child: Container(height: 1, color: tg.borderHi)),
      ],
    );
  }
}

/// 部件行（`.part-row`）：部位徽章 + 装备名 + 部位说明 / 项圈出战效果。
class _PartRow extends StatelessWidget {
  const _PartRow({required this.slot, this.collar});

  final PetSuitSlot slot;

  /// 项圈专用：出战后生效的系列效果。
  final String? collar;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final note = collar == null ? slot.note : '出战后$collar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        children: [
          // 部位图标（游戏内道具图，取自珍兽装备图鉴截图）
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: _slotIcon(slot.icon).image(
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: TgSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.name,
                  style: TgType.row13.copyWith(
                    color: tg.t1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  note,
                  style: TgType.caption.copyWith(
                    color: collar == null ? tg.t3 : tg.gold2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 消耗行（左侧说明 + 右侧数值）。
class _CostLine extends StatelessWidget {
  const _CostLine({
    required this.text,
    required this.value,
    this.accent = false,
  });

  final String text;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TgType.caption.copyWith(color: tg.t3, height: 1.5),
            ),
          ),
          const SizedBox(width: TgSpacing.sm),
          Text(
            value,
            style: TgType.row13.copyWith(
              color: accent ? tg.gold2 : tg.t1,
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
      SuitMatCalcInput(lv: lv, targetStar: star, withExchange: withExchange),
    );
    return TgCard(
      width: double.infinity,
      basePadding: const EdgeInsets.all(22),
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
              TgSegmented(
                values: kSuitLvKeys,
                selected: lv,
                onSelect: onLvChanged,
              ),
              const SizedBox(width: TgSpacing.s10),
              _CalcLabel(text: '目标星级'),
              TgSegmented(
                values: const ['1★', '2★', '3★', '4★', '5★'],
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
          // 兑换 / 合计 两个模块并排（左兑换、右合计；窄屏上下堆叠）
          LayoutBuilder(
            builder: (context, c) {
              final exchange = result.exchangeSet > 0
                  ? _CalcModule(
                      title: '兑换 $lv 级套装 1★ · 5 件',
                      child: _MatItem(
                        name: kSuitMatName,
                        count: result.exchangeSet,
                        note: '每件 ${result.exchangePerPiece} 个',
                      ),
                    )
                  : null;
              final total = _CalcModule(
                title: '合计消耗',
                titleColor: tg.gold2,
                child: _MatItem(
                  name: kSuitMatName,
                  count: result.total,
                  note: '兑换 + 升星 · 5 件',
                ),
              );
              if (exchange == null || c.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exchange != null) ...[
                      exchange,
                      const SizedBox(height: TgSpacing.s14),
                    ],
                    total,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: exchange),
                  const SizedBox(width: TgSpacing.s14),
                  Expanded(child: total),
                ],
              );
            },
          ),
          const SizedBox(height: TgSpacing.s18),
          // 升星（1★ 起到目标星级，逐星）
          if (result.starRows.isNotEmpty) ...[
            _SectionTitle(title: '升星 1★ → $star★ · $lv 级 · 5 件'),
            const SizedBox(height: TgSpacing.sm),
            for (final row in result.starRows) _StarLine(row: row),
            const SizedBox(height: TgSpacing.md),
          ] else ...[
            _SectionTitle(title: '升星 · $lv 级 · 5 件'),
            const SizedBox(height: TgSpacing.sm),
            Text(
              '目标 1★：只需兑换 1★ 整套，无需升星。',
              style: TgType.caption.copyWith(color: tg.t3),
            ),
            const SizedBox(height: TgSpacing.md),
          ],
          // 合计（已与兑换模块并排在上方）
          const SizedBox(height: TgSpacing.s14),
          Text(
            '※ $lv 级档参考：兑换 1★ 每件 ${result.exchangePerPiece} 个，'
            '升星（1★ → 5★）逐星每件 ${kSuitMatCost[lv]!.starUp.join(' / ')} 个，'
            '整套 5 件「兑换 + 升满 5★」共 ${result.fullSetTotal} 个；'
            '拆解返还（每件 1★~5★）${result.salvagePerPiece.join(' / ')} 个。',
            style: TgType.caption.copyWith(color: tg.t3, height: 1.6),
          ),
          const SizedBox(height: TgSpacing.xs),
          Text(
            '※ 「目标星级」为想做到的星级：1★ 只需兑换 1★ 整套，5★ 为兑换 + 逐星升满；'
            '逐星消耗按 5 件计，「含兑换材料」用于计入 / 排除兑换 1★ 的圣兽鳞。'
            '75 档部件也可由煞星副本掉落。圣兽鳞由拆解珍兽套装获得（副本不直接掉落），'
            '兑换 / 升星 / 拆解均在苏州（248，184）云姗姗处，另有少量金钱消耗。',
            style: TgType.caption.copyWith(color: tg.t3, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// 计算器内的模块：标题在上、内容在下（无卡片边框 / 无选中态）。
class _CalcModule extends StatelessWidget {
  const _CalcModule({required this.title, required this.child, this.titleColor});

  final String title;
  final Widget child;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TgType.caption.copyWith(
            color: titleColor ?? tg.t3,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: TgSpacing.s10),
        child,
      ],
    );
  }
}

class _CalcLabel extends StatelessWidget {
  const _CalcLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Text(text, style: TgType.label.copyWith(color: tg.t3));
  }
}

/// 材料条目（`.mat-item`）：徽章 + 名称 + 数量（+ 说明）。
class _MatItem extends StatelessWidget {
  const _MatItem({required this.name, required this.count, this.note});

  final String name;

  /// 数量（单位：个）。
  final int count;

  /// 附加说明，如「每件 1 个」。
  final String? note;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
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
              name.substring(0, 1),
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
              Text(name, style: TgType.caption.copyWith(color: tg.t2)),
              Text(
                '× $count 个',
                style: TgType.row13.copyWith(
                  color: tg.t1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (note != null)
                Text(note!, style: TgType.caption.copyWith(color: tg.t3)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单星级升星行（`.star-line`）：目标星级 + 每件消耗 + 整套 5 件消耗。
class _StarLine extends StatelessWidget {
  const _StarLine({required this.row});

  final SuitMatStarRow row;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row.star - 1}★ → ${row.star}★',
            style: TgType.row13.copyWith(
              color: tg.gold2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: TgSpacing.s10),
          Expanded(
            child: Text(
              '每件 ×${row.perPiece} 个　·　5 件 ×${row.setTotal} 个',
              style: TgType.caption.copyWith(color: tg.t2, height: 1.5),
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
            '套装与圣兽鳞数据按怀旧服（经典版宝宝套）公开资料整理，如与游戏内不符以官方为准',
            textAlign: TextAlign.center,
            style: TgType.tag.copyWith(color: tg.t3),
          ),
        ],
      ),
    );
  }
}
