import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/pet_prob.dart';

/// 宝宝技能释放概率（对应原型 `v-pet-prob`）。
///
/// 页头 + 两行筛选 chips（性格 / 分类）+ 技能列表卡 + 公式说明。
/// - 性格 chips：通用 / 勇猛 / 胆小 / 谨慎 / 精明 / 忠诚 / 内敛；
/// - 分类 chips：全部 / 攻击类 / 状态类 / 辅助类；
/// - 列表行：技能名（+描述）/ 类型 tag / 概率条 + 百分比 / 判定 tag；
/// - 概率 = 实测基准值 × 性格修正系数（上限 100%），逻辑见 `pet_prob.dart`。
///
/// 页面不含 Scaffold/AppBar（信息条与返回按钮由 shell 框架提供）。
class PetProbPage extends StatefulWidget {
  const PetProbPage({super.key});

  @override
  State<PetProbPage> createState() => _PetProbPageState();
}

class _PetProbPageState extends State<PetProbPage> {
  /// 当前性格（默认「通用」）。
  PetChar _char = kPetChars.first;

  /// 当前分类筛选（null = 全部）。
  PetSkillCat? _cat;

  List<PetSkill> get _visibleSkills => _cat == null
      ? kPetSkills
      : kPetSkills.where((s) => s.cat == _cat).toList(growable: false);

  /// 打开技能详情弹窗（对应原型 skillModal / openSkillDetail）。
  void _openDetail(PetSkill skill) {
    showTgModal(
      context: context,
      child: _SkillDetailDialog(skill: skill, char: _char),
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
                      crumbLeft: ToolCatalog.petProb.crumbRoot,
                      crumbTail: ToolCatalog.petProb.crumb.substring(
                        ToolCatalog.petProb.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.petProb.group.hubLocation),
                      title: ToolCatalog.petProb.title,
                      subtitle: ToolCatalog.petProb.pageSubtitle,
                    ),
                    // 性格 chips
                    Wrap(
                      spacing: TgSpacing.s9,
                      runSpacing: TgSpacing.sm,
                      children: [
                        for (final c in kPetChars)
                          _TgChip(
                            label: c.name,
                            active: c.key == _char.key,
                            onTap: () => setState(() => _char = c),
                          ),
                      ],
                    ),
                    const SizedBox(height: TgSpacing.s10),
                    // 分类 chips
                    Wrap(
                      spacing: TgSpacing.s9,
                      runSpacing: TgSpacing.sm,
                      children: [
                        _TgChip(
                          label: '全部',
                          active: _cat == null,
                          onTap: () => setState(() => _cat = null),
                        ),
                        for (final cat in PetSkillCat.values)
                          _TgChip(
                            label: cat.label,
                            active: _cat == cat,
                            onTap: () => setState(() => _cat = cat),
                          ),
                      ],
                    ),
                    const SizedBox(height: TgSpacing.md),
                    // 列表卡
                    _ProbListCard(
                      compact: compact,
                      char: _char,
                      skills: _visibleSkills,
                      onDetail: _openDetail,
                    ),
                    const SizedBox(height: TgSpacing.s14),
                    const _FormulaNote(),
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

/// 筛选 chip（胶囊 · 选中金色提亮）。
class _TgChip extends StatefulWidget {
  const _TgChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TgChip> createState() => _TgChipState();
}

class _TgChipState extends State<_TgChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final active = widget.active;
    final hover = _hover;
    // 描边优先级：active 金 .5 > hover 金 .45 > borderHi（原型 .chip/.chip:hover）
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
            // 原型 .chip：padding 6.5px 15px · 12.5px · active 底 .10
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

/// 技能列表卡（`.list-card`）：表头 + 行。
class _ProbListCard extends StatelessWidget {
  const _ProbListCard({
    required this.compact,
    required this.char,
    required this.skills,
    required this.onDetail,
  });

  final bool compact;
  final PetChar char;
  final List<PetSkill> skills;
  final ValueChanged<PetSkill> onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          // 表头（移动端隐藏，对应 @media 640 .list-head{display:none}）
          if (!compact) ...[
            _ListHead(),
            // 表头与首行之间：表头自带 border-bottom
          ],
          for (var i = 0; i < skills.length; i++) ...[
            _ProbRow(
              compact: compact,
              skill: skills[i],
              char: char,
              last: i == skills.length - 1,
              onDetail: onDetail,
            ),
          ],
        ],
      ),
    );
  }
}

/// 表头：技能 / 类型 / 触发概率 / 判定 / 详情。
class _ListHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: tg.inset2,
        border: Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 125, child: _headText(tg, '技能')),
          Expanded(flex: 75, child: _headText(tg, '类型')),
          Expanded(flex: 150, child: _headText(tg, '触发概率')),
          Expanded(flex: 55, child: _headText(tg, '判定', right: true)),
          Expanded(flex: 50, child: _headText(tg, '详情', right: true)),
        ],
      ),
    );
  }

  Widget _headText(TgColors tg, String s, {bool right = false}) {
    return Text(
      s,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: TgType.note.copyWith(color: tg.t3, letterSpacing: 1.5),
    );
  }
}

/// 列表行（`.lrow`）。
///
/// 桌面：4 列 1.25fr/.75fr/1.5fr/.55fr；
/// 移动端：首行 名称+tag，第二行 概率条全宽，第三行 判定（对应 @media 640）。
class _ProbRow extends StatelessWidget {
  const _ProbRow({
    required this.compact,
    required this.skill,
    required this.char,
    required this.last,
    required this.onDetail,
  });

  final bool compact;
  final PetSkill skill;
  final PetChar char;
  final bool last;
  final ValueChanged<PetSkill> onDetail;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final p = petProbOf(skill, char);
    final w = petProbBarWidth(p);

    final name = _SkillName(skill: skill);
    final typeTag = _Tag(label: skill.tag, color: skill.tagColor);
    final bar = _ProbBar(p: p, w: w);
    final judgeTag = _Tag(label: skill.judge);

    if (compact) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: tg.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: name),
                const SizedBox(width: TgSpacing.s12),
                typeTag,
              ],
            ),
            const SizedBox(height: TgSpacing.s9),
            bar,
            const SizedBox(height: TgSpacing.s9),
            judgeTag,
            const SizedBox(height: 6),
            // 移动端详情按钮整行右对齐（对应 @media 640 .sk-info）
            Align(
              alignment: Alignment.centerRight,
              child: _DetailButton(onTap: () => onDetail(skill)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: last
            ? null
            : Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 125, child: name),
          // Align 使 tag 按内容自适应宽度（Expanded 直接包裹会撑满整列）
          Expanded(
            flex: 75,
            child: Align(alignment: Alignment.centerLeft, child: typeTag),
          ),
          Expanded(flex: 150, child: bar),
          Expanded(
            flex: 55,
            child: Align(alignment: Alignment.centerRight, child: judgeTag),
          ),
          Expanded(
            flex: 50,
            child: Align(
              alignment: Alignment.centerRight,
              child: _DetailButton(onTap: () => onDetail(skill)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 技能名（可含描述 small）。
class _SkillName extends StatelessWidget {
  const _SkillName({required this.skill});

  final PetSkill skill;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Text.rich(
      TextSpan(
        // 原型 .l-name：13.5px · 500；描述 small 11/t3
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: tg.t1,
        ),
        children: [
          TextSpan(text: skill.name),
          if (skill.hasDesc)
            TextSpan(
              text: '\n${skill.desc}',
              style: TgType.tag.copyWith(color: tg.t3, height: 1.4),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 概率条：6px 轨道 + 金渐变填充 + 百分比。
class _ProbBar extends StatelessWidget {
  const _ProbBar({required this.p, required this.w});

  final int p;
  final int w;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: tg.inset,
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: w / 100,
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
        const SizedBox(width: TgSpacing.s10),
        SizedBox(
          width: 44,
          child: Text(
            '$p%',
            textAlign: TextAlign.right,
            // 原型 .l-pct：13.5px · 600
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: tg.gold2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// 类型 / 判定 tag（`.tag` + `.tag-<color>`）。
class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color});

  final String label;

  /// 类型 tag 颜色；null 为普通 tag（判定用，t2/border-hi）。
  final PetTagColor? color;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    Color text;
    Color border;
    Color bg;
    switch (color) {
      case null:
        text = tg.t2;
        border = tg.borderHi;
        bg = Colors.transparent;
      case PetTagColor.gold:
        text = tg.gold2;
        border = tg.goldTint(.4);
        bg = tg.goldTint(.08);
      case PetTagColor.blue:
        text = tg.tagBlue;
        border = tg.tagBorderOf(tg.blue);
        bg = tg.tintOf(tg.blue, .08);
      case PetTagColor.green:
        text = tg.tagGreen;
        border = tg.tagBorderOf(tg.green);
        bg = tg.tintOf(tg.green, .08);
      case PetTagColor.red:
        text = tg.tagRed;
        border = tg.tagBorderOf(tg.red);
        bg = tg.tintOf(tg.red, .08);
      case PetTagColor.cyan:
        text = tg.tagCyan;
        border = tg.tagBorderOf(tg.cyan);
        bg = tg.tintOf(tg.cyan, .08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TgRadius.sm),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(label, style: TgType.tag.copyWith(color: text, height: 1.7)),
    );
  }
}

/// 公式说明（`.note`）：info 图标 + 文案，inset 底。
class _FormulaNote extends StatelessWidget {
  const _FormulaNote();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TgSpacing.s13,
        vertical: TgSpacing.s11,
      ),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(TgRadius.lg),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TgIcon('info', size: 15, color: tg.goldDp),
          const SizedBox(width: TgSpacing.s9),
          Expanded(
            child: Text(
              '概率 = 实测基准值 × 性格修正系数（上限 100%），实际还受悟性与技能等级影响。',
              style: TgType.note.copyWith(color: tg.t3, letterSpacing: 0),
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

/// 详情按钮（对应原型 `.sk-info`）：book 图标 + 详情，hover 泛金。
class _DetailButton extends StatefulWidget {
  const _DetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DetailButton> createState() => _DetailButtonState();
}

class _DetailButtonState extends State<_DetailButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final fg = _hover ? tg.gold2 : tg.t2;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _hover ? tg.goldTint(.09) : tg.inset,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hover ? tg.goldTint(.5) : tg.borderHi,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TgIcon('book', size: 13, color: fg),
                const SizedBox(width: 5),
                Text(
                  '详情',
                  style: TextStyle(fontSize: 11.5, letterSpacing: 1, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 技能详情弹窗（对应原型 skillModal）：图标/名称/双 tag + 长描述 +
/// 三格数据（基准概率 · 当前性格概率 · 判定方式）+ 公式注。
class _SkillDetailDialog extends StatelessWidget {
  const _SkillDetailDialog({required this.skill, required this.char});

  final PetSkill skill;
  final PetChar char;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final current = petProbOf(skill, char);
    final nowLabel = char.key == 'general' ? '通用概率' : '${char.name}性格概率';

    // 图标配色（对应原型 .tile + .tile.t-<color>）
    final Color iconC;
    final Color tileBorder;
    final Color tileBg;
    switch (skill.tagColor) {
      case PetTagColor.gold:
        iconC = tg.gold2;
        tileBorder = tg.goldTint(.45);
        tileBg = tg.goldTint(.10);
      case PetTagColor.cyan:
        iconC = tg.tagCyan;
        tileBorder = tg.tagBorderOf(tg.cyan);
        tileBg = tg.tintOf(tg.cyan, .10);
      case PetTagColor.red:
        iconC = tg.tagRed;
        tileBorder = tg.tagBorderOf(tg.red);
        tileBg = tg.tintOf(tg.red, .10);
      case PetTagColor.blue:
        iconC = tg.tagBlue;
        tileBorder = tg.tagBorderOf(tg.blue);
        tileBg = tg.tintOf(tg.blue, .10);
      case PetTagColor.green:
        iconC = tg.tagGreen;
        tileBorder = tg.tagBorderOf(tg.green);
        tileBg = tg.tintOf(tg.green, .10);
    }

    // 外壳/卡片由共享 TgModalShell 提供（Dialog 内自带 Material 上下文，
    // 正文文字不会出现黄色双下划线）。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // modal-head：图标 + 名称/双 tag + 关闭
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: tileBorder, width: 1),
              ),
              child: SvgPicture.asset(
                'assets/icons/${skill.icon}.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(iconC, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: tg.t1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(label: skill.tag, color: skill.tagColor),
                      const SizedBox(width: 5),
                      _Tag(label: skill.cat.label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TgModalCloseButton(onTap: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 15),
        // sk-fx：长描述
        Text(
          skill.fx,
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 13, height: 1.8, color: tg.t2),
        ),
        const SizedBox(height: 15),
        // sk-stat3：三格数据
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Stat3Cell(value: '${skill.base}%', label: '基准概率'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat3Cell(value: '$current%', label: nowLabel),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat3Cell(value: skill.judge, label: '判定方式', text: true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '※ 概率 = 基准值 × 性格系数（上限 100%），实际还受悟性与技能等级影响。',
          style: TextStyle(fontSize: 11.5, color: tg.t3),
        ),
      ],
    );
  }
}

/// sk-stat3 单格：大数字 + 下注（b / span）。
class _Stat3Cell extends StatelessWidget {
  const _Stat3Cell({
    required this.value,
    required this.label,
    this.text = false,
  });

  final String value;
  final String label;

  /// 判定方式格：文字为大字号（17→13，对应 `.sk-stat3 b.txt`）。
  final bool text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: text ? 13 : 17,
              fontWeight: FontWeight.w600,
              color: tg.gold2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, letterSpacing: 1, color: tg.t3),
          ),
        ],
      ),
    );
  }
}
