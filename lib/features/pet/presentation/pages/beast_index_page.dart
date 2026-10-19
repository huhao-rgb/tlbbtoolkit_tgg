import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/features/pet/domain/beast_spirit.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/page_head.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_text_field.dart';

/// 兽灵图鉴（对应原型 v1.13.0 `v-beast-index` · 兽灵手风琴版）。
///
/// 页面结构：
/// - `.calc-note` 说明 → 兽灵以珍兽技能为单位划分，20 级 7 阶、两个效果位；
/// - `阶位结构 · 20 级 7 阶`：7 段金色进度条 + 阶位 / 等级区间；
/// - `兽灵技能图鉴`：类型 chips（全部 / 被动技能 / 手动技能，对应小程序两个
///   页签）+ 手风琴（`.bsacc-item`）罗列兽灵，**同时仅一项展开**；已收录完整
///   数据的兽灵按 7 阶 chips 切换「阶位说明 + 两个效果位」，其余展示攻略共识。
///
/// 与 v1.11.1 版（流派筛选 + 星级卡片网格 + 成长档位弹窗）为**整体替换**。
class BeastIndexPage extends StatefulWidget {
  const BeastIndexPage({super.key});

  @override
  State<BeastIndexPage> createState() => _BeastIndexPageState();
}

class _BeastIndexPageState extends State<BeastIndexPage> {
  /// 技能类型筛选；null = 全部。
  BeastSpiritKind? _kind;

  /// 搜索词（空 = 不过滤）。匹配技能名 / 定位 / 任意阶位文案。
  String _query = '';

  /// 当前展开的兽灵 id；null = 全部收起。
  ///
  /// 默认展开首项（破御）：原型初始态虽无 `.open`，但整页内容全靠手风琴
  /// 承载，首屏全收起过于空，故默认展开首项。用 id 而非下标记录，切换筛选后
  /// 不会因为下标错位而展开到别的兽灵。
  String? _open = kBeastSpirits.first.id;

  /// 各兽灵当前选中的阶位（收起后保留，对应原型 DOM 状态不重置）。
  final Map<String, int> _tierSel = <String, int>{};

  /// 类型 + 关键词过滤后的兽灵。
  List<BeastSpirit> _filtered(BeastSpiritKind? kind, String query) {
    final q = query.trim();
    return kBeastSpirits
        .where((s) => kind == null || s.kind == kind)
        .where((s) => q.isEmpty || _matches(s, q))
        .toList(growable: false);
  }

  /// 是否命中关键词：技能名 / 定位 / 7 阶任意文案（去标记后包含匹配）。
  bool _matches(BeastSpirit s, String q) {
    if (s.name.contains(q) || s.sub.contains(q)) return true;
    for (final t in s.tiers) {
      if (_plainText(t.dec).contains(q) ||
          _plainText(t.effect1).contains(q) ||
          _plainText(t.effect2).contains(q)) {
        return true;
      }
    }
    return false;
  }

  /// 当前筛选下可见的兽灵。
  List<BeastSpirit> get _visible => _filtered(_kind, _query);

  /// 切换类型筛选，并默认展开新列表首项（避免展开项被筛掉后一片空白）。
  void _selectKind(BeastSpiritKind? kind) {
    setState(() {
      _kind = kind;
      final list = _filtered(_kind, _query);
      _open = list.isEmpty ? null : list.first.id;
    });
  }

  /// 更新搜索词，并默认展开首个命中项。
  void _search(String query) {
    setState(() {
      _query = query;
      final list = _filtered(_kind, _query);
      _open = list.isEmpty ? null : list.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
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
                      crumbLeft: ToolCatalog.beastIndex.crumbRoot,
                      crumbTail: ToolCatalog.beastIndex.crumb.substring(
                        ToolCatalog.beastIndex.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.beastIndex.group.hubLocation),
                      title: ToolCatalog.beastIndex.title,
                      subtitle: ToolCatalog.beastIndex.pageSubtitle,
                    ),
                    // 顶部说明（.calc-note，margin-bottom 14）
                    const _CalcNote(text: kBeastIndexIntroNote, markup: true),
                    const SizedBox(height: 18),
                    // 阶位结构 · 20 级 7 阶（.mat-sec）
                    const _SectionTitle(title: '阶位结构 · 20 级 7 阶'),
                    // .mat-sec h4 margin-bottom 10
                    const SizedBox(height: 10),
                    const _TierStructure(),
                    const SizedBox(height: 18),
                    // 兽灵技能图鉴（.mat-sec）
                    const _SectionTitle(
                      title: '兽灵技能图鉴',
                      trailing: _Tag('点击展开 · 同时仅一项'),
                    ),
                    // .mat-sec h4 margin-bottom 10（标题含 tag 时行高更高，需留白）
                    const SizedBox(height: 10),
                    // 搜索框（技能名 / 效果关键词）+ 类型筛选 chips
                    // （类型对应小程序「兽灵被动技能 / 兽灵手动技能」页签）
                    LayoutBuilder(
                      builder: (context, c) {
                        final search = _SearchField(
                          value: _query,
                          onChanged: _search,
                          onClear: () => _search(''),
                        );
                        final chips = Wrap(
                          spacing: 9,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: '全部',
                              active: _kind == null,
                              onTap: () => _selectKind(null),
                            ),
                            for (final k in BeastSpiritKind.values)
                              _Chip(
                                label: k.label,
                                active: _kind == k,
                                onTap: () => _selectKind(k),
                              ),
                          ],
                        );
                        // 窄屏：搜索框独占一行，chips 换行；宽屏：搜索框 280 + chips
                        if (c.maxWidth < 640) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              search,
                              const SizedBox(height: 10),
                              chips,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            SizedBox(width: 280, child: search),
                            const SizedBox(width: 14),
                            Expanded(child: chips),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      _EmptyHint(kind: _kind, query: _query)
                    else
                      Column(
                        children: [
                          for (final (i, s) in visible.indexed) ...[
                            _BeastAccItem(
                              spirit: s,
                              open: _open == s.id,
                              onToggle: () => setState(
                                () => _open = _open == s.id ? null : s.id,
                              ),
                              tierIndex: _tierSel[s.id] ?? 0,
                              onTier: (t) => setState(() => _tierSel[s.id] = t),
                            ),
                            // .bsacc-item margin-bottom 10；末项与底部说明取 14
                            SizedBox(height: i == visible.length - 1 ? 14 : 10),
                          ],
                        ],
                      ),
                    // 底部说明（.calc-note）
                    const _CalcNote(text: kBeastIndexFootNote),
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

/// 空态：搜索无结果，或该类型（如「手动技能」）暂未收录。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.kind, this.query = ''});

  final BeastSpiritKind? kind;

  /// 当前搜索词；非空时优先提示「无匹配」。
  final String query;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final q = query.trim();
    final label = kind?.label ?? '';
    final text = q.isEmpty ? '$label数据待补' : '没有匹配「$q」的技能，换个关键词试试';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: BorderRadius.circular(TgRadius.r12),
        border: Border.all(color: tg.goldTint(.26), width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, height: 1.7, color: tg.t3),
      ),
    );
  }
}

/// 搜索框（技能名 / 定位 / 效果关键词），带「清空」。
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgTextField(
      controller: _c,
      hintText: '搜索技能名或效果，如「冰精」「剧毒陷阱」「昏睡」…',
      prefixIcon: 'search',
      fontSize: 12.5,
      height: 38,
      horizontalPadding: 12,
      radius: BorderRadius.circular(9),
      onChanged: widget.onChanged,
      suffix: widget.value.isEmpty
          ? null
          : InkWell(
              onTap: () {
                _c.clear();
                widget.onClear();
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('清空', style: TextStyle(fontSize: 11, color: tg.t3)),
              ),
            ),
    );
  }
}

/// 小节标题（`.mat-sec h4`）：标题 + 可选 tag + 右侧填充细线。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;

  /// 标题右侧附加内容（如「点击展开 · 同时仅一项」tag）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: tg.t3,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: tg.borderHi)),
      ],
    );
  }
}

/// 说明文字（`.calc-note`）：11.5 / t3；[markup] 时解析 `<b>` 为金强调。
class _CalcNote extends StatelessWidget {
  const _CalcNote({required this.text, this.markup = false});

  final String text;
  final bool markup;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final base = TextStyle(fontSize: 11.5, height: 1.7, color: tg.t3);
    if (!markup) return Text(text, style: base);
    return Text.rich(
      TextSpan(children: _markupSpans(text, base, boldColor: tg.gold2)),
    );
  }
}

/// 阶位结构：7 段金色进度条 + 阶位 / 等级区间。
class _TierStructure extends StatelessWidget {
  const _TierStructure();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        for (var i = 0; i < kBeastTierSteps.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                // 6px 高金色渐变条（原型 linear-gradient(90deg,#d9b96c,#b98a3d)）
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [tg.gold, tg.goldDp],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${kBeastTierSteps[i].name}\n${kBeastTierSteps[i].lv}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, height: 1.35, color: tg.t3),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 单只兽灵的手风琴卡（`.bsacc-item`）。
class _BeastAccItem extends StatefulWidget {
  const _BeastAccItem({
    required this.spirit,
    required this.open,
    required this.onToggle,
    required this.tierIndex,
    required this.onTier,
  });

  final BeastSpirit spirit;
  final bool open;
  final VoidCallback onToggle;

  /// 当前选中的阶位下标（仅完整数据兽灵使用）。
  final int tierIndex;
  final ValueChanged<int> onTier;

  @override
  State<_BeastAccItem> createState() => _BeastAccItemState();
}

class _BeastAccItemState extends State<_BeastAccItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final s = widget.spirit;
    return Container(
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: BorderRadius.circular(TgRadius.r12),
        // .bsacc-item：常态即淡金描边 rgba(217,185,108,.26)
        border: Border.all(color: tg.goldTint(.26), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // bsacc-head
          MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            cursor: SystemMouseCursors.click,
            child: Material(
              color: _hover ? tg.goldTint(.06) : Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      // 名称 + 定位（+ tag）占满左侧，箭头恒靠右
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: tg.t1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                s.sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: tg.t3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 9),
                      // bsacc-arrow：收起朝下 → 展开旋转 180° 朝上
                      AnimatedRotation(
                        turns: widget.open ? .75 : .25,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: TgIcon('chev', size: 12, color: tg.gold2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // bsacc-body：展开 / 收起（原型 max-height .32s ease）
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.ease,
              alignment: Alignment.topCenter,
              child: widget.open
                  ? _Body(
                      spirit: s,
                      tierIndex: widget.tierIndex,
                      onTier: widget.onTier,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 手风琴内容（`.bsacc-body-in`：padding 2 / 15 / 15）。
class _Body extends StatelessWidget {
  const _Body({
    required this.spirit,
    required this.tierIndex,
    required this.onTier,
  });

  final BeastSpirit spirit;
  final int tierIndex;
  final ValueChanged<int> onTier;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgCardPadding(
      base: const EdgeInsets.fromLTRB(15, 2, 15, 15),
      child: spirit.isComplete
          ? _CompleteBody(spirit: spirit, tierIndex: tierIndex, onTier: onTier)
          : _PendingBody(spirit: spirit, textColor: tg.t2),
    );
  }
}

/// 完整数据兽灵：7 阶 chips + 阶位说明 / 两个效果位。
class _CompleteBody extends StatelessWidget {
  const _CompleteBody({
    required this.spirit,
    required this.tierIndex,
    required this.onTier,
  });

  final BeastSpirit spirit;
  final int tierIndex;
  final ValueChanged<int> onTier;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final tier = spirit.tiers[tierIndex];
    final decStyle = TextStyle(fontSize: 13, height: 1.7, color: tg.t1);
    final fxStyle = TextStyle(fontSize: 12.5, height: 1.6, color: tg.t2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // chips：一阶 · 1-3 级 … 七阶 · 20 级
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            for (var i = 0; i < spirit.tiers.length; i++)
              _Chip(
                label: '${spirit.tiers[i].name} · ${spirit.tiers[i].lv}',
                active: i == tierIndex,
                onTap: () => onTier(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // .card：阶位说明 + 效果一 / 效果二
        TgCard(
          basePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tier.name,
                      style: decStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tg.gold2,
                      ),
                    ),
                    TextSpan(text: '（兽灵 ${tier.lv}）', style: decStyle),
                    const TextSpan(text: '\n'),
                    ..._markupSpans(tier.dec, decStyle, boldColor: tg.t1),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SoulFx(
                spans: _markupSpans(
                  '<b>兽灵效果一</b> · ${tier.effect1}',
                  fxStyle,
                  boldColor: tg.gold2,
                  italicColor: tg.t3,
                ),
              ),
              const SizedBox(height: 8),
              _SoulFx(
                spans: _markupSpans(
                  '<b>兽灵效果二</b> · ${tier.effect2}',
                  fxStyle,
                  boldColor: tg.gold2,
                  italicColor: tg.t3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 待补兽灵：攻略共识正文 + `※` 注。
class _PendingBody extends StatelessWidget {
  const _PendingBody({required this.spirit, required this.textColor});

  final BeastSpirit spirit;

  /// 正文色（原型 `color:var(--t2)`）。
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final bodyStyle = TextStyle(fontSize: 12.5, height: 1.7, color: textColor);
    final fxStyle = TextStyle(fontSize: 12.5, height: 1.6, color: tg.t2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: _markupSpans(
              spirit.pendingBody,
              bodyStyle,
              boldColor: textColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SoulFx(
          spans: _markupSpans(
            spirit.pendingNote,
            fxStyle,
            boldColor: tg.gold2,
            italicColor: tg.t3,
          ),
        ),
      ],
    );
  }
}

/// 效果条（`.soul-fx`）：3px 金左边线 + 金淡底 + 右圆角。
class _SoulFx extends StatelessWidget {
  const _SoulFx({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tg.goldTint(.07),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        border: Border(left: BorderSide(color: tg.gold2, width: 3)),
      ),
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}

/// 阶位 chip（`.chip` / `.chip.active`）。
class _Chip extends StatefulWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
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

/// 标签（`.tag`）：小节标题右侧的弱化说明。
class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TgRadius.sm),
        border: Border.all(color: tg.borderHi, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, height: 1.7, color: tg.t2),
      ),
    );
  }
}

/// 去掉富文本标记，得到纯文本（供搜索匹配用）。
String _plainText(String raw) => raw
    .replaceAll('<b>', '')
    .replaceAll('</b>', '')
    .replaceAll('<i>', '')
    .replaceAll('</i>', '');

/// 文案标记解析：`<b>…</b>` → [boldColor] 加粗，`<i>…</i>` → 斜体弱化。
///
/// 数据（[kBeastSpirits]）沿用原型 HTML 的富文本标记，表现层在此还原。
/// 原型中 `.soul-fx b` 为金强调，其余 `<b>` 继承正文色加粗；`<i>` 无独立
/// 样式（浏览器默认斜体），此处按弱文字 [italicColor] 处理。
final RegExp _markupRe = RegExp(r'<(b|i)>(.*?)</\1>', dotAll: true);

List<InlineSpan> _markupSpans(
  String raw,
  TextStyle base, {
  Color? boldColor,
  Color? italicColor,
}) {
  final out = <InlineSpan>[];
  var last = 0;
  for (final m in _markupRe.allMatches(raw)) {
    if (m.start > last) {
      out.add(TextSpan(text: raw.substring(last, m.start), style: base));
    }
    final inner = m.group(2)!;
    out.add(
      TextSpan(
        text: inner,
        style: m.group(1) == 'b'
            ? base.copyWith(color: boldColor, fontWeight: FontWeight.w600)
            : base.copyWith(color: italicColor, fontStyle: FontStyle.italic),
      ),
    );
    last = m.end;
  }
  if (last < raw.length) {
    out.add(TextSpan(text: raw.substring(last), style: base));
  }
  return out;
}
