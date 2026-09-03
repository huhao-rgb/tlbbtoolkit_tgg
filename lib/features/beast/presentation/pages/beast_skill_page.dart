import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/beast_skill.dart';

/// 兽灵技能效果（对应原型 `v-beast-skill`）。
///
/// 手风琴（`.acc-list`）罗列 5 个兽灵技能；点击标题展开
/// Lv.1-5 等级数值表（`.lv-tbl`），多个可同时展开。
class BeastSkillPage extends StatefulWidget {
  const BeastSkillPage({super.key});

  @override
  State<BeastSkillPage> createState() => _BeastSkillPageState();
}

class _BeastSkillPageState extends State<BeastSkillPage> {
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
                      crumbLeft: ToolCatalog.beastSkill.crumbRoot,
                      crumbTail: ToolCatalog.beastSkill.crumb.substring(
                        ToolCatalog.beastSkill.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.beastSkill.group.hubLocation),
                      title: ToolCatalog.beastSkill.title,
                      subtitle: ToolCatalog.beastSkill.pageSubtitle,
                    ),
                    // 手风琴列表（默认第一项展开）
                    Column(
                      children: [
                        for (var i = 0; i < kBeastSkills.length; i++) ...[
                          if (i > 0) const SizedBox(height: 11),
                          _AccCard(
                            skill: kBeastSkills[i],
                            initiallyOpen: i == 0,
                          ),
                        ],
                      ],
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

/// 单张手风琴卡（`.acc`）。
class _AccCard extends StatefulWidget {
  const _AccCard({required this.skill, required this.initiallyOpen});

  final BeastSkill skill;
  final bool initiallyOpen;

  @override
  State<_AccCard> createState() => _AccCardState();
}

class _AccCardState extends State<_AccCard> {
  late bool _open = widget.initiallyOpen;
  bool _hover = false;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final skill = widget.skill;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        // .acc.open：展开后卡片描边泛金
        border: Border.all(
          color: _open ? tg.goldTint(.3) : tg.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // acc-head
          MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: _toggle,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                // 原型 .acc-head:hover → var(--hovrow)：深 白2.5% / 浅 黑3.5%
                color: _hover
                    ? (tg.brightness == Brightness.dark
                          ? const Color(0x06FFFFFF)
                          : const Color(0x092A251D))
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // acc-title：名称 + 类别 tag
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  skill.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: tg.t1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _KindTag(kind: skill.kind),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // acc-brief
                          Text(
                            skill.brief,
                            style: TextStyle(fontSize: 12, color: tg.t3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 13),
                    // acc-chev：折叠指向右 → 展开旋转 90°（向下）并泛金
                    AnimatedRotation(
                      turns: _open ? 0.25 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: TgIcon(
                        'chev',
                        size: 18,
                        color: _open ? tg.gold : tg.t3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // acc-body：展开/收起（原型 max-height .32s ease）
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.ease,
              alignment: Alignment.topCenter,
              child: _open ? _LvTable(skill: skill) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 等级数值表（`.lv-tbl`）。
class _LvTable extends StatelessWidget {
  const _LvTable({required this.skill});

  final BeastSkill skill;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      // .lv-tbl padding：2 / 20 / 16
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      child: Column(
        children: [
          for (var i = 0; i < skill.rows.length; i++)
            _LvRow(
              row: skill.rows[i],
              zebra: tg.brightness == Brightness.light, // 深色无斑马纹
            ),
        ],
      ),
    );
  }
}

/// 单条等级数值行（`.lv-row`）。
class _LvRow extends StatelessWidget {
  const _LvRow({required this.row, required this.zebra});

  final BeastSkillRow row;

  /// 是否显示斑马纹（原型深色主题 `--lv-alt` 无效 → 无斑马）。
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: zebra ? tg.tintOf(tg.t1, .03) : Colors.transparent,
        border: Border(top: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          // b：Lv.1（56px 固定列）
          SizedBox(
            width: 56,
            child: Text(
              row.lv,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: tg.gold2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 效果（1fr）
          Expanded(
            flex: 10,
            child: Text(
              row.effect,
              style: TextStyle(fontSize: 12.5, color: tg.t2),
            ),
          ),
          const SizedBox(width: 12),
          // 冷却 / 触发（.9fr，右对齐弱色）
          Expanded(
            flex: 9,
            child: Text(
              row.note,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.5, color: tg.t3),
            ),
          ),
        ],
      ),
    );
  }
}

/// 类别 tag（主动=金 / 被动=紫 / 控制=蓝，对应 `.tag tag-gold/purple/blue`）。
class _KindTag extends StatelessWidget {
  const _KindTag({required this.kind});

  final BeastSkillKind kind;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final Color text;
    final Color border;
    final Color bg;
    switch (kind) {
      case BeastSkillKind.active:
        text = tg.gold2;
        border = tg.goldTint(.4);
        bg = tg.goldTint(.08);
      case BeastSkillKind.passive:
        text = tg.tagPurple;
        border = tg.tagBorderOf(tg.purple);
        bg = tg.tintOf(tg.purple, .08);
      case BeastSkillKind.control:
        text = tg.tagBlue;
        border = tg.tagBorderOf(tg.blue);
        bg = tg.tintOf(tg.blue, .08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        kind.label,
        style: TextStyle(fontSize: 11, height: 1.7, color: text),
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
