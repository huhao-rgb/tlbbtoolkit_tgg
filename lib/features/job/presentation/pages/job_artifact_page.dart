import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/job_artifact.dart';
import '../../domain/job_sect.dart';
import '../widgets/job_common.dart';
import '../widgets/job_sect_widgets.dart';

/// 职业神器（对应原型 `v-class-artifact`）。
///
/// 门派筛选 + 门派名/定位 tag；卡片内含「蓝色剑砖 + 神器名 + 等级 tag +
/// 档位分段(42/62/82/102)」头部、神器简介、基础属性、神兵特性
/// 与获取途径；点档位切换该门派该档神器详情。
class JobArtifactPage extends StatefulWidget {
  const JobArtifactPage({super.key});

  @override
  State<JobArtifactPage> createState() => _JobArtifactPageState();
}

class _JobArtifactPageState extends State<JobArtifactPage> {
  /// 当前门派（默认少林，对应原型 `afSt.sect='shaolin'`）。
  JobSect _sect = kJobSects.firstWhere((s) => s.key == 'shaolin');

  /// 当前档位（0~3 → 42/62/82/102）。
  int _tier = 0;

  JobArtifact get _artifact => kJobArtifacts[_sect.key]!;

  JobArtifactTier get _t => _artifact.tiers[_tier];

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
                    // 神器详情卡
                    Container(
                      padding: const EdgeInsets.all(18),
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
                                labels: [
                                  for (final t in _artifact.tiers) '${t.lv}',
                                ],
                                selected: _tier,
                                onSelect: (i) => setState(() => _tier = i),
                              );
                              final head = Row(
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
                                          _t.name,
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
                                        _LvTag(lv: _t.lv),
                                      ],
                                    ),
                                  ),
                                  if (c.maxWidth >= 420) ...[
                                    const SizedBox(width: 12),
                                    seg,
                                  ],
                                ],
                              );
                              if (c.maxWidth < 420) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    head,
                                    const SizedBox(height: 12),
                                    seg,
                                  ],
                                );
                              }
                              return head;
                            },
                          ),
                          // afIntro：神器简介（金 soul-fx）
                          JobSoulFx(
                            title: '神器简介',
                            text: '${_t.intro}（适配武器：${_artifact.weapon}）',
                            top: 16,
                          ),
                          // 基础属性
                          const SizedBox(height: 18),
                          const JobSectionTitle('基础属性'),
                          const SizedBox(height: 10),
                          JobMatRow(
                            compact: compact,
                            items: [
                              for (var i = 0; i < _t.stats.length; i++)
                                JobMatItem(
                                  label: _t.stats[i].name,
                                  value: '+${_t.stats[i].value}',
                                  badge: '${i + 1}',
                                ),
                            ],
                          ),
                          // afExtra：神兵特性（蓝 soul-fx）
                          JobSoulFx(
                            title: '神兵特性',
                            text: _t.extra,
                            top: 18,
                            accent: JobSoulAccent.blue,
                          ),
                          // 获取途径
                          const SizedBox(height: 18),
                          const JobSectionTitle('获取途径'),
                          const SizedBox(height: 6),
                          for (var i = 0; i < _t.how.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _HowStep(index: i + 1, text: _t.how[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // note
                    const JobNote(
                      text: '神器每 20 级一档（42 / 62 / 82 / 102），重铸继承强化与词条；数值为参考基准，实际以游戏内为准。',
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

/// 档位分段（`.lv-seg`）：42 / 62 / 82 / 102。
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
