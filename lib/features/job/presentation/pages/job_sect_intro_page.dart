import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/features/job/data/job_catalog.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/page_head.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_bar_row.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';
import 'package:tlbbtoolkit/features/job/domain/job_point.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect_info.dart';
import 'package:tlbbtoolkit/features/job/presentation/widgets/job_common.dart';
import 'package:tlbbtoolkit/features/job/presentation/widgets/job_sect_widgets.dart';

/// 门派介绍（对应原型 `v-class-sect`）。
///
/// 门派筛选 + 门派名/定位 tag；卡片内含门派简介、门派特色、
/// 属性倾向（潜能加点权重条形图）、适合人群；
/// 下方「深入这个门派」四个入口卡跳转相关工具。
class JobSectIntroPage extends ConsumerStatefulWidget {
  const JobSectIntroPage({super.key});

  @override
  ConsumerState<JobSectIntroPage> createState() => _JobSectIntroPageState();
}

class _JobSectIntroPageState extends ConsumerState<JobSectIntroPage> {
  /// 当前门派（默认少林，对应原型 `siSt.sect='shaolin'`）。
  JobSect _sect = kJobSects.firstWhere((s) => s.key == 'shaolin');

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
                      crumbLeft: ToolCatalog.jobSect.crumbRoot,
                      crumbTail: ToolCatalog.jobSect.crumb.substring(
                        ToolCatalog.jobSect.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.jobSect.group.hubLocation),
                      title: ToolCatalog.jobSect.title,
                      subtitle: ToolCatalog.jobSect.pageSubtitle,
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
                    // 门派名 + 定位 tag（siName · siType，透明底）
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
                        JobSectTag(sect: _sect, filled: false),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 门派介绍卡
                    TgCard(
                      basePadding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tg.card,
                        borderRadius: TgRadius.card,
                        border: Border.all(color: tg.border, width: 1),
                      ),
                      child: _SectDetail(
                        sect: _sect,
                        compact: compact,
                        info:
                            ref
                                .watch(jobSectInfoCatalogProvider)
                                .value?[_sect.key] ??
                            kJobSectInfo[_sect.key]!,
                      ),
                    ),
                    // 深入这个门派
                    const SizedBox(height: 16),
                    const JobSectionTitle('深入这个门派'),
                    const SizedBox(height: 10),
                    _ExploreGrid(compact: compact, sectKey: _sect.key),
                    const SizedBox(height: 14),
                    const JobNote(text: '门派背景为原创演绎，属性倾向为参考建议；实际表现请以游戏内为准。'),
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

/// 门派详情块：简介 / 特色 / 属性倾向 / 适合人群。
class _SectDetail extends StatelessWidget {
  const _SectDetail({
    required this.sect,
    required this.compact,
    required this.info,
  });

  final JobSect sect;
  final bool compact;
  final JobSectInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // siIntro：门派简介（金 soul-fx，无上间距）
        JobSoulFx(title: '门派简介', text: info.intro, top: 0),
        // 主要属性（siAttrs：属性攻 / 主修 / 攻系 标签）
        if (info.atk.isNotEmpty) ...[
          const SizedBox(height: 18),
          const JobSectionTitle('主要属性'),
          const SizedBox(height: 10),
          _AttrTags(info: info, sectColor: Color(sect.colorValue)),
          // 伤害系数（「伤害系数总表」本门派那一行）
          const SizedBox(height: 14),
          _DmgCoefBlock(dmg: info.dmg),
        ],
        // 背景渊源（siBg）
        if (info.bg.isNotEmpty) ...[
          const SizedBox(height: 18),
          const JobSectionTitle('背景渊源'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: context.tg.inset,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: context.tg.border, width: 1),
            ),
            child: Text(
              info.bg,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.75,
                color: context.tg.t2,
              ),
            ),
          ),
        ],
        // 门派特色
        const SizedBox(height: 18),
        const JobSectionTitle('门派特色'),
        const SizedBox(height: 10),
        JobMatRow(
          compact: compact,
          items: [
            for (var i = 0; i < info.traits.length; i++)
              JobMatItem(
                label: info.traits[i].label,
                value: info.traits[i].value,
                badge: '${i + 1}',
              ),
          ],
        ),
        // 门派生活技能（siLifeSec；无可隐藏）
        if (info.life.isNotEmpty) ...[
          const SizedBox(height: 18),
          const JobSectionTitle('门派生活技能'),
          const SizedBox(height: 10),
          JobMatRow(
            compact: compact,
            items: [
              for (final l in info.life)
                JobMatItem(
                  label: l.name,
                  value:
                      l.desc +
                      (l.at != null && l.at!.isNotEmpty
                          ? '\n学习地点：${l.at}'
                          : ''),
                  badge: '技',
                ),
            ],
          ),
        ],
        // 属性倾向 · 潜能加点参考
        const SizedBox(height: 18),
        const JobSectionTitle('属性倾向 · 潜能加点参考'),
        const SizedBox(height: 12),
        _WeightBars(sect: sect),
        // 适合人群（绿 soul-fx）
        JobSoulFx(
          title: '适合人群',
          text: info.suit,
          top: 16,
          accent: JobSoulAccent.green,
        ),
      ],
    );
  }
}

/// 主要属性标签行（`siAttrs`：属性攻 / 主修 / 攻系）。
class _AttrTags extends StatelessWidget {
  const _AttrTags({required this.info, required this.sectColor});

  final JobSectInfo info;
  final Color sectColor;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    // 属性攻标签用门派色描边
    Widget tag(String text, {Color? color}) {
      final c = color ?? tg.t2;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.withValues(alpha: .38), width: 1),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: c)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in info.atk) tag(a, color: sectColor),
        tag('主修 ${info.main}'),
        tag('攻系 ${info.atype}'),
      ],
    );
  }
}

/// 伤害系数（「伤害系数总表」里本门派那一行：内外功 + 冰火玄毒）。
///
/// 六格数值：外功 / 内功伤害系数与四属性系数；属性系数 `> 1` 用金色强调，
/// 数据缺失时退化为一行说明（目前十三门派齐全）。
class _DmgCoefBlock extends StatelessWidget {
  const _DmgCoefBlock({required this.dmg});

  final JobDamageCoef? dmg;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final coef = dmg;
    if (coef == null) {
      return Text(
        '※ 暂无该门派的伤害系数（总表尚未收录）。',
        style: TextStyle(fontSize: 11, color: tg.t3),
      );
    }
    final cells = <_DmgCellData>[
      _DmgCellData(label: '外功伤害', value: coef.phys),
      _DmgCellData(label: '内功伤害', value: coef.magic),
      _DmgCellData(label: '冰', value: coef.ice, labelColor: tg.blue),
      _DmgCellData(label: '火', value: coef.fire, labelColor: tg.red),
      _DmgCellData(label: '玄', value: coef.xuan, labelColor: tg.purple),
      _DmgCellData(label: '毒', value: coef.poison, labelColor: tg.green),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        // 窄屏放三列两行，避免 0.003875 这类六位小数被压扁
        final cols = c.maxWidth < 520 ? 3 : 6;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '伤害系数',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: tg.t2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: tg.borderHi)),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final cell in cells)
                  SizedBox(
                    width: w,
                    child: _DmgCell(data: cell),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '※ 属性系数以 1 为基准，>1 表示该属性伤害有额外加成。\n'
              '※ 系数取自玩家整理的「伤害系数总表」；实际伤害还受内外功攻击、'
              '目标防御与抗性影响。',
              style: TextStyle(fontSize: 11, color: tg.t3, height: 1.6),
            ),
          ],
        );
      },
    );
  }
}

/// 单格伤害系数（小标签 + 数值）。
class _DmgCellData {
  const _DmgCellData({
    required this.label,
    required this.value,
    this.labelColor,
  });

  final String label;
  final double value;

  /// 标签色（四属性用各自的元素色，内外功留空走三级灰）。
  final Color? labelColor;
}

class _DmgCell extends StatelessWidget {
  const _DmgCell({required this.data});

  final _DmgCellData data;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final boosted = data.value > 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: tg.inset2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: boosted ? tg.goldTint(.32) : tg.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: data.labelColor ?? tg.t3),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              jobDmgCoefText(data.value),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: boosted ? tg.gold2 : tg.t1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 属性倾向：五维权重百分比条形图（门派色渐变）。
class _WeightBars extends StatelessWidget {
  const _WeightBars({required this.sect});

  final JobSect sect;

  @override
  Widget build(BuildContext context) {
    final w = kJobWeights[sect.key] ?? const {};
    final sum = w.values.fold<double>(0, (a, b) => a + b);
    final base = Color(sect.colorValue);
    return Column(
      children: [
        for (final attr in kJobAttrs) ...[
          _WeightRow(
            label: attr.label,
            pct: ((w[attr.key] ?? 0) / (sum == 0 ? 1 : sum) * 100).round(),
            gradient: LinearGradient(
              colors: [base.withValues(alpha: .4), base],
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

/// 单条权重行（`名字 + bar + pct%`）。
class _WeightRow extends StatelessWidget {
  const _WeightRow({
    required this.label,
    required this.pct,
    required this.gradient,
  });

  final String label;
  final int pct;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgBarRow(
      label: label,
      widthFactor: pct / 100,
      labelWidth: 36,
      labelAlign: TextAlign.left,
      labelStyle: TextStyle(fontSize: 12.5, color: tg.t2),
      gradient: gradient,
      bottom: 0,
      trailingWidth: 38,
      trailing: Text(
        '$pct%',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: tg.gold2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// 深入这个门派：四个入口卡（技能库 / 神器 / 武道 / 加点计算器）。
class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid({required this.compact, required this.sectKey});

  final bool compact;

  /// 当前门派 key（跳转时作为 `?sect=` 参数携带，目标页定位到该门派）。
  final String sectKey;

  /// 目标页 location + `?sect=` 当前门派。
  String _loc(String base) => '$base?sect=$sectKey';

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ExploreData(
        name: '技能库',
        desc: '类型 · 冷却 · 描述',
        icon: 'book',
        location: _loc(ToolCatalog.jobSkill.location),
      ),
      _ExploreData(
        name: '神器',
        desc: '42-102 级四档',
        icon: 'sword',
        location: _loc(ToolCatalog.jobArtifact.location),
      ),
      _ExploreData(
        name: '武道',
        desc: '四重 · 双路线技能树',
        icon: 'flame',
        location: _loc(ToolCatalog.jobWudao.location),
      ),
      _ExploreData(
        name: '加点计算器',
        desc: '潜能方案 · 面板预览',
        icon: 'slider',
        location: _loc(ToolCatalog.jobPoint.location),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        const minTile = 180.0;
        final cols = compact
            ? 1
            : (((c.maxWidth + gap) / (minTile + gap)).floor()).clamp(1, 4);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: w,
                child: _ExploreCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

/// 深入入口数据。
class _ExploreData {
  const _ExploreData({
    required this.name,
    required this.desc,
    required this.icon,
    required this.location,
  });

  final String name;
  final String desc;
  final String icon;
  final String location;
}

/// 单个深入入口（紧凑 tool-card：蓝砖 + 名/描述 + chev）。
class _ExploreCard extends StatefulWidget {
  const _ExploreCard({required this.data});

  final _ExploreData data;

  @override
  State<_ExploreCard> createState() => _ExploreCardState();
}

class _ExploreCardState extends State<_ExploreCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
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
            onTap: () => context.go(widget.data.location),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  // 蓝色 class 砖
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tg.tintOf(tg.blue, .10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tg.tintOf(tg.blue, .28),
                        width: 1,
                      ),
                    ),
                    child: TgIcon(widget.data.icon, size: 21, color: tg.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TgType.cardTitle.copyWith(color: tg.t1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.data.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TgType.caption.copyWith(color: tg.t3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(_hover ? 3 : 0, 0, 0),
                    child: TgIcon(
                      'chev',
                      size: 16,
                      color: _hover ? tg.gold : tg.t3,
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
