import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_card.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/job_sect.dart';
import '../../domain/job_skill.dart';
import '../../domain/job_skill_icons.dart';
import '../widgets/job_sect_widgets.dart';

/// 职业技能库（对应原型 `v-class-skill`）。
///
/// 门派筛选 + 心法筛选（全部 / 七本心法）+ 技能列表。
/// 「全部」时按七本心法分组（`xf-head`），选单本心法则只列出该组技能；
/// 每门技能显示 名称 / 类型 tag / 冷却 / 描述（`.skill-rows`）。
class JobSkillPage extends StatefulWidget {
  const JobSkillPage({super.key, this.initialSect});

  /// 初始门派 key（如 `shaolin`；来自门派介绍页「深入这个门派」跳转）。
  /// 为空时保持默认逍遥。
  final String? initialSect;

  @override
  State<JobSkillPage> createState() => _JobSkillPageState();
}

class _JobSkillPageState extends State<JobSkillPage> {
  /// 当前门派（默认逍遥，对应原型 `skSect='xiaoyao'`；
  /// 可由 `initialSect` 覆盖，支持跨页定位门派）。
  late JobSect _sect;

  /// 当前心法序号；-1 = 全部（对应原型 `skMind`，`'all'`）。
  int _mind = -1;

  List<JobMind> get _minds => kJobMinds[_sect.key] ?? const [];

  List<JobSkill> get _skills => kJobSkills[_sect.key] ?? const [];

  @override
  void initState() {
    super.initState();
    final key = widget.initialSect;
    _sect = (key != null && kJobSects.any((s) => s.key == key))
        ? kJobSects.firstWhere((s) => s.key == key)
        : kJobSects.firstWhere((s) => s.key == 'xiaoyao');
  }

  void _selectSect(JobSect s) => setState(() {
    _sect = s;
    _mind = -1; // 切换门派后回到全部
  });

  void _selectMind(int i) => setState(() => _mind = i);

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
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
                      crumbLeft: ToolCatalog.jobSkill.crumbRoot,
                      crumbTail: ToolCatalog.jobSkill.crumb.substring(
                        ToolCatalog.jobSkill.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.jobSkill.group.hubLocation),
                      title: ToolCatalog.jobSkill.title,
                      subtitle: ToolCatalog.jobSkill.pageSubtitle,
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
                            onTap: () => _selectSect(s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 选中门派名 + 定位 tag（skName · skType）
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _sect.name,
                          style: TextStyle(
                            fontFamily: TgFonts.serif,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: tg.t1,
                          ),
                        ),
                        const SizedBox(width: 11),
                        JobSectTag(sect: _sect),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 心法筛选 chips（全部 + 七本心法）
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _MindChip(
                          label: '全部',
                          active: _mind == -1,
                          onTap: () => _selectMind(-1),
                        ),
                        for (var i = 0; i < _minds.length; i++)
                          _MindChip(
                            label: _minds[i].name,
                            active: _mind == i,
                            onTap: () => _selectMind(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // xf-note：心法计数 / 说明（超长可点击展开）
                    _MindNote(mind: _mind == -1 ? null : _minds[_mind], total: _skills.length),
                    const SizedBox(height: 14),
                    // 技能列表卡片
                    _SkillList(
                      minds: _minds,
                      skills: _skills,
                      selectedMind: _mind,
                      compact: compact,
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

/// 心法筛选 chip（`.chip`）。
class _MindChip extends StatefulWidget {
  const _MindChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_MindChip> createState() => _MindChipState();
}

class _MindChipState extends State<_MindChip> {
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
              color: active ? tg.goldTint(.1) : Colors.transparent,
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

/// 技能类型 → tag 配色（对应原型 `tagCls`）。
({Color text, Color border, Color bg}) _toneOfSkillType(
  BuildContext context,
  String type,
) {
  final tg = context.tg;
  Color text;
  Color border;
  Color bg;
  switch (type) {
    case '攻击':
      text = tg.gold2;
      border = tg.goldTint(.4);
      bg = tg.goldTint(.08);
    case '主动':
    case '状态':
    case '复活':
      text = tg.tagBlue;
      border = tg.tagBorderOf(tg.blue);
      bg = tg.tintOf(tg.blue, .08);
    case '治疗':
    case '增益':
    case '辅助':
      text = tg.tagGreen;
      border = tg.tagBorderOf(tg.green);
      bg = tg.tintOf(tg.green, .08);
    case '被动':
    case '陷阱':
      text = tg.tagPurple;
      border = tg.tagBorderOf(tg.purple);
      bg = tg.tintOf(tg.purple, .08);
    case '控制':
    case '保命':
    case '火系':
      text = tg.tagRed;
      border = tg.tagBorderOf(tg.red);
      bg = tg.tintOf(tg.red, .08);
    default: // 身法 / 解控 / 冰系 → 青色
      text = tg.tagCyan;
      border = tg.tagBorderOf(tg.cyan);
      bg = tg.tintOf(tg.cyan, .08);
  }
  return (text: text, border: border, bg: bg);
}

/// 技能列表卡片（`.card list-card skill-rows`）。
class _SkillList extends StatelessWidget {
  const _SkillList({
    required this.minds,
    required this.skills,
    required this.selectedMind,
    required this.compact,
  });

  final List<JobMind> minds;
  final List<JobSkill> skills;
  final int selectedMind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final showAll = selectedMind == -1;
    // 按心法分组（全部时展示全部分组，否则仅选中那组）
    final groups = <int, List<JobSkill>>{};
    for (final s in skills) {
      if (!showAll && s.mind != selectedMind) continue;
      groups.putIfAbsent(s.mind, () => []).add(s);
    }
    final empty = groups.isEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (empty)
            const _EmptyState()
          else ...[
            if (!compact) const _ListHead(),
            for (var mi = 0; mi < minds.length; mi++)
              if (groups.containsKey(mi)) ...[
                if (showAll) ...[
                  _MindHead(
                    mind: minds[mi],
                    count: groups[mi]!.length,
                    compact: compact,
                  ),
                ],
                for (final s in groups[mi]!)
                  _SkillRow(skill: s, compact: compact),
              ],
          ],
        ],
      ),
    );
  }
}

/// 表头（`.list-head`，移动端隐藏）。
class _ListHead extends StatelessWidget {
  const _ListHead();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final label = TextStyle(fontSize: 11.5, letterSpacing: 1.5, color: tg.t3);
    return TgCard(
      basePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: tg.inset2,
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(width: 250, child: Text('技能', style: label)),
          SizedBox(width: 110, child: Text('类型', style: label)),
          SizedBox(width: 80, child: Text('冷却', style: label)),
          Expanded(child: Text('描述', style: label)),
        ],
      ),
    );
  }
}

/// 顶部心法说明（`xf-note`）：全部时显示计数；
/// 选中单本心法时显示「心法名 · 描述」，超长可点击展开/收起。
class _MindNote extends StatefulWidget {
  const _MindNote({required this.mind, required this.total});

  /// 当前选中的心法；null = 全部。
  final JobMind? mind;

  /// 该门派技能总数。
  final int total;

  @override
  State<_MindNote> createState() => _MindNoteState();
}

class _MindNoteState extends State<_MindNote> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final mind = widget.mind;
    if (mind == null) {
      return Text(
        '七本心法 · 共 ${widget.total} 门绝技 —— 点击心法名可单独查看',
        style: TextStyle(fontSize: 12, color: tg.t3, height: 1.5),
      );
    }
    final style = TextStyle(fontSize: 12, color: tg.t3, height: 1.55);
    return Align(
      alignment: Alignment.centerLeft,
      child: _ExpandableText(
        text: '「${mind.name}」 · ${mind.desc}',
        expanded: _expanded,
        onToggle: () => setState(() => _expanded = !_expanded),
        style: style,
      ),
    );
  }
}

/// 心法分组头（`.xf-head`）。
class _MindHead extends StatefulWidget {
  const _MindHead({
    required this.mind,
    required this.count,
    required this.compact,
  });

  final JobMind mind;
  final int count;
  final bool compact;

  @override
  State<_MindHead> createState() => _MindHeadState();
}

class _MindHeadState extends State<_MindHead> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 16 : 20,
        11,
        widget.compact ? 16 : 20,
        10,
      ),
      decoration: BoxDecoration(
        color: tg.inset2,
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            widget.mind.name,
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: tg.gold,
            ),
          ),
          const SizedBox(width: 10),
          // 心法介绍（`xf-head` 描述）：Expanded 约束避免超长官网文案溢出；
          // 超 2 行时点击展开 / 再点收起。
          Expanded(
            child: _ExpandableText(
              text: '${widget.mind.desc} · ${widget.count} 门',
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: .5,
                color: tg.t3,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 可展开/收起的文本：
/// - 未溢出（collapsedMaxLines 内显示得下）→ 普通文本，不可点；
/// - 溢出 → 默认折叠省略号，点击展开全文 / 再点收起，并带「展开 / 收起」提示。
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({
    required this.text,
    required this.expanded,
    required this.onToggle,
    required this.style,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  final TextStyle style;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final collapsed = !widget.expanded;
    final plainStyle = widget.style;

    // 按实际可用宽度测量折叠态是否溢出，决定是否需要展开交互
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: plainStyle),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: maxW);
        final overflows = tp.didExceedMaxLines;

        final hint = collapsed ? ' 展开' : ' 收起';
        final hintStyle = TextStyle(
          fontSize: 11,
          color: tg.gold,
          fontWeight: FontWeight.w500,
        );

        if (!overflows) {
          // 未溢出：普通多行文本（保留换行能力）
          return Text(widget.text, style: plainStyle);
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.text,
                  maxLines: collapsed ? 2 : null,
                  overflow: collapsed ? TextOverflow.ellipsis : null,
                  style: plainStyle,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(hint, style: hintStyle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 技能图标（`.sk-ic`：30×30 圆角，居中对齐）。
class _SkillIcon extends StatelessWidget {
  const _SkillIcon({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: 30,
          height: 30,
          color: context.tg.inset,
        ),
      ),
    );
  }
}

/// 单行技能（`.lrow`：名称 / 类型 tag / 冷却 / 描述）。
class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.compact});

  final JobSkill skill;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final tone = _toneOfSkillType(context, skill.type);
    if (compact) {
      return TgCard(
        width: double.infinity,
        basePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tg.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 技能图标（对齐原型 `.sk-ic`）
                if (kJobSkillIcons[skill.name] != null) ...[
                  _SkillIcon(path: kJobSkillIcons[skill.name]!),
                  const SizedBox(width: 8),
                ],
                // 技能名
                Expanded(
                  child: Text(
                    skill.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: tg.t1,
                    ),
                  ),
                ),
                // 类型 tag
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tone.bg,
                    borderRadius: BorderRadius.circular(TgRadius.sm),
                    border: Border.all(color: tone.border, width: 1),
                  ),
                  child: Text(
                    skill.type,
                    style: TgType.tag.copyWith(color: tone.text, height: 1.7),
                  ),
                ),
                // 冷却
                Text(
                  skill.cd,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tg.t1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            // 描述占整行
            Text(
              skill.desc,
              style: TextStyle(fontSize: 12.5, color: tg.t2, height: 1.5),
            ),
          ],
        ),
      );
    }
    return TgCard(
      width: double.infinity,
      basePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: tg.card,
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            child: Row(
              children: [
                // 技能图标（对齐原型 `.sk-ic`）
                if (kJobSkillIcons[skill.name] != null) ...[
                  _SkillIcon(path: kJobSkillIcons[skill.name]!),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    skill.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: tg.t1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            // tag 按内容自适应宽度（原型 `.l-mid` 内 inline-flex），左对齐
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tone.bg,
                  borderRadius: BorderRadius.circular(TgRadius.sm),
                  border: Border.all(color: tone.border, width: 1),
                ),
                child: Text(
                  skill.type,
                  style: TgType.tag.copyWith(color: tone.text, height: 1.7),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              skill.cd,
              style: TextStyle(
                fontSize: 12.5,
                color: tg.t1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              skill.desc,
              style: TextStyle(fontSize: 12.5, color: tg.t2),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空状态（心法暂无收录技能）。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Text(
          '该心法暂无收录技能 · 我们正在加急整理',
          style: TextStyle(fontSize: 13, color: tg.t3),
        ),
      ),
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
