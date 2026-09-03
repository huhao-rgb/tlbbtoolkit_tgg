import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/job_point.dart';
import '../../domain/job_sect.dart';
import '../../domain/job_sect_info.dart';
import '../widgets/job_common.dart';
import '../widgets/job_sect_widgets.dart';

/// 门派介绍（对应原型 `v-class-sect`）。
///
/// 门派筛选 + 门派名/定位 tag；卡片内含门派简介、门派特色、
/// 属性倾向（潜能加点权重条形图）、适合人群；
/// 下方「深入这个门派」四个入口卡跳转相关工具。
class JobSectIntroPage extends StatefulWidget {
  const JobSectIntroPage({super.key});

  @override
  State<JobSectIntroPage> createState() => _JobSectIntroPageState();
}

class _JobSectIntroPageState extends State<JobSectIntroPage> {
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
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tg.card,
                        borderRadius: TgRadius.card,
                        border: Border.all(color: tg.border, width: 1),
                      ),
                      child: _SectDetail(sect: _sect, compact: compact),
                    ),
                    // 深入这个门派
                    const SizedBox(height: 16),
                    const JobSectionTitle('深入这个门派'),
                    const SizedBox(height: 10),
                    _ExploreGrid(compact: compact),
                    const SizedBox(height: 14),
                    const JobNote(text: '门派背景为原创演绎，属性倾向为参考建议；实际表现请以游戏内为准。'),
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

/// 门派详情块：简介 / 特色 / 属性倾向 / 适合人群。
class _SectDetail extends StatelessWidget {
  const _SectDetail({required this.sect, required this.compact});

  final JobSect sect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = kJobSectInfo[sect.key]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // siIntro：门派简介（金 soul-fx，无上间距）
        JobSoulFx(title: '门派简介', text: info.intro, top: 0),
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
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(label, style: TextStyle(fontSize: 12.5, color: tg.t2)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: tg.inset,
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '$pct%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
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

/// 深入这个门派：四个入口卡（技能库 / 神器 / 武道 / 加点计算器）。
class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ExploreData(
        name: '技能库',
        desc: '类型 · 冷却 · 描述',
        icon: 'book',
        location: ToolCatalog.jobSkill.location,
      ),
      _ExploreData(
        name: '神器',
        desc: '42-102 级四档',
        icon: 'sword',
        location: ToolCatalog.jobArtifact.location,
      ),
      _ExploreData(
        name: '武道',
        desc: '四重 · 双路线技能树',
        icon: 'flame',
        location: ToolCatalog.jobWudao.location,
      ),
      _ExploreData(
        name: '加点计算器',
        desc: '潜能方案 · 面板预览',
        icon: 'slider',
        location: ToolCatalog.jobPoint.location,
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
