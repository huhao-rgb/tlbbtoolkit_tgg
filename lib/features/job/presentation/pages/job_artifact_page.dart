import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/features/job/data/job_artifacts_repository.dart';
import 'package:tlbbtoolkit/features/job/domain/job_artifact.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect.dart';
import 'package:tlbbtoolkit/features/job/presentation/widgets/job_common.dart';
import 'package:tlbbtoolkit/features/job/presentation/widgets/job_sect_widgets.dart';
import 'package:tlbbtoolkit/shared/tools/tool_catalog.dart';
import 'package:tlbbtoolkit/shared/widgets/app_async_view.dart';
import 'package:tlbbtoolkit/shared/widgets/page_head.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_card.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_entrance.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_page_foot.dart';

/// 职业神器（对应原型 `v-class-artifact`）。
///
/// 门派筛选 + 门派名/定位 tag；卡片内含「蓝色剑砖 + 神器名 + 等级 tag +
/// 档位分段(42~102 九档)」头部、神器简介、基础属性、神兵特性
/// 与获取途径；点档位切换该门派该档神器详情。
class JobArtifactPage extends ConsumerStatefulWidget {
  const JobArtifactPage({super.key, this.initialSect});

  /// 初始门派 key（如 `shaolin`；来自门派介绍页「深入这个门派」跳转）。
  /// 为空时保持默认少林。
  final String? initialSect;

  @override
  ConsumerState<JobArtifactPage> createState() => _JobArtifactPageState();
}

class _JobArtifactPageState extends ConsumerState<JobArtifactPage> {
  /// 当前门派（默认少林，对应原型 `afSt.sect='shaolin'`；
  /// 可由 `initialSect` 覆盖，支持跨页定位门派）。
  late JobSect _sect;

  /// 当前档位（0~8 → 42/52/62/72/82/86/92/96/102）。
  int _tier = 0;

  @override
  void initState() {
    super.initState();
    final key = widget.initialSect;
    _sect = (key != null && kJobSects.any((s) => s.key == key))
        ? kJobSects.firstWhere((s) => s.key == key)
        : kJobSects.firstWhere((s) => s.key == 'shaolin');
  }

  @override
  Widget build(BuildContext context) {
    return AppAsyncView<Map<String, JobArtifact>>(
      value: ref.watch(jobArtifactsProvider),
      onRetry: () => ref.invalidate(jobArtifactsProvider),
      dataBuilder: _buildContent,
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, JobArtifact> artifacts,
  ) {
    // 分片可能少某个门派：优先用该门派的常量兜底，而不是错拿别家门派的神器
    final artifact = artifacts[_sect.key] ?? kJobArtifacts[_sect.key];
    // 昆仑等新门派官方尚未公布九档数据：页头与门派切换仍要能渲染，
    // 仅神器卡位换成占位提示（原先直接返回空组件会让整页失去入口）。
    final tiers = artifact?.tiers ?? const <JobArtifactTier>[];
    final tier = tiers.isEmpty ? null : tiers[_tier.clamp(0, tiers.length - 1)];

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
                      crumbLeft: ToolCatalog.jobArtifact.crumbRoot,
                      crumbTail: ToolCatalog.jobArtifact.crumb.substring(
                        ToolCatalog.jobArtifact.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.jobArtifact.group.hubLocation),
                      title: ToolCatalog.jobArtifact.title,
                      subtitle: ToolCatalog.jobArtifact.pageSubtitle,
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
                            onTap: () => setState(() {
                              _sect = s;
                              _tier = 0;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 门派名 + 定位 tag（afName · afType，透明底）
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
                    // 神器详情卡（缺数据时换成占位提示）
                    if (tier == null)
                      const _NoArtifactNote()
                    else
                      TgCard(
                        basePadding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: tg.card,
                          borderRadius: TgRadius.card,
                          border: Border.all(color: tg.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 头部：剑砖 + 神器名 + 等级 tag + 档位分段
                            LayoutBuilder(
                              builder: (context, c) {
                                final seg = _LvSeg(
                                  labels: [for (final t in tiers) '${t.lv}'],
                                  selected: _tier,
                                  onSelect: (i) => setState(() => _tier = i),
                                );
                                final nameRow = Row(
                                  children: [
                                    // tile.class：蓝剑砖 44
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
                                      child: TgIcon(
                                        'sword',
                                        size: 21,
                                        color: tg.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // suit-name：神器名（serif）
                                          Text(
                                            tier.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: TgFonts.serif,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                              color: tg.t1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // tag-gold：42 级神器
                                          _LvTag(lv: tier.lv),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                                // 九档分段约 325px，与神器名同排需 ≥ 560 宽；否则换行并可横向滚动。
                                if (c.maxWidth < 560) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      nameRow,
                                      const SizedBox(height: 12),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: seg,
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: nameRow),
                                    const SizedBox(width: 12),
                                    seg,
                                  ],
                                );
                              },
                            ),
                            // afIntro：神器简介（金 soul-fx）
                            JobSoulFx(
                              title: '神器简介',
                              text: '${tier.intro}（适配武器：${artifact!.weapon}）',
                              top: 16,
                            ),
                            // 基础属性
                            const SizedBox(height: 18),
                            const JobSectionTitle('基础属性'),
                            const SizedBox(height: 10),
                            JobMatRow(
                              compact: compact,
                              items: [
                                for (var i = 0; i < tier.stats.length; i++)
                                  _statItem(tier.stats[i], i + 1),
                              ],
                            ),
                            // afExtra：神兵特性（蓝 soul-fx）
                            JobSoulFx(
                              title: '神兵特性',
                              text: tier.extra,
                              top: 18,
                              accent: JobSoulAccent.blue,
                            ),
                            // 获取途径
                            const SizedBox(height: 18),
                            const JobSectionTitle('获取途径'),
                            const SizedBox(height: 6),
                            for (var i = 0; i < tier.how.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _HowStep(index: i + 1, text: tier.how[i]),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    // note
                    const JobNote(
                      text:
                          '神器共九档（42/52/62/72/82/86/92/96/102）：42~92 级同名升阶（血浴神兵铸造，'
                          '新莽神符 1~6 级 = 5/10/15/20 个，杀怪 1000 只），86/96 级由 82/92 级以神兵符 ×5「炼魂」'
                          '进阶为门派专属神器，102 级为门派专属太古神器；重铸继承强化与词条；数值为参考基准，实际以游戏内为准。',
                    ),
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

/// 把原型 `'名称 +数值'` 形式的属性文案拆成「名称 / 数值」两列。
JobMatItem _statItem(String spec, int index) {
  final parts = spec.split(' +');
  return JobMatItem(
    label: parts.first,
    value: parts.length > 1 ? '+${parts[1]}' : spec,
    badge: '$index',
  );
}

/// 等级 tag（`.tag-gold`：42 级神器）。
class _LvTag extends StatelessWidget {
  const _LvTag({required this.lv});

  final int lv;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tg.goldTint(.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tg.goldTint(.4), width: 1),
      ),
      child: Text(
        '$lv 级神器',
        style: TextStyle(fontSize: 11, height: 1.7, color: tg.gold2),
      ),
    );
  }
}

/// 档位分段（`.lv-seg`）：42 / 52 / 62 / 72 / 82 / 86 / 92 / 96 / 102。
class _LvSeg extends StatelessWidget {
  const _LvSeg({
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

/// 获取途径单步（`.how-step`：圆序号 + 文本）。
class _HowStep extends StatelessWidget {
  const _HowStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tg.gold2, width: 1),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tg.gold2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: tg.t2, height: 1.55),
          ),
        ),
      ],
    );
  }
}

/// 该门派神器数据未收录时的占位卡（如昆仑：官方只公布了神器名，九档未公开）。
class _NoArtifactNote extends StatelessWidget {
  const _NoArtifactNote();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            '官网暂未公布该门派神器数据',
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: tg.t2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '42-102 级九档的属性与获取途径尚未公开，整理完成后会补入。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: tg.t3, height: 1.7),
          ),
        ],
      ),
    );
  }
}
