import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_card.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/job_sect.dart';
import '../../domain/job_wudao.dart';
import '../widgets/job_sect_widgets.dart';

/// 职业武道（对应原型 `v-class-wudao`）。
///
/// 门派筛选（`.sect-row`）+ 选中门派名与定位 tag +
/// 该门派官网武道流派卡（`.wudao-grid`）：
/// 每流派卡含流派被动（wd-pd）与各「重」节点（wd-lname + wd-row，
/// 同层择一、每重 5 级）；节点带 30×30 图标。
/// 慕容 / 曼陀山庄暂无官网武道数据，显示占位提示。
class JobWudaoPage extends StatefulWidget {
  const JobWudaoPage({super.key, this.initialSect});

  /// 初始门派 key（如 `shaolin`；来自门派介绍页「深入这个门派」跳转）。
  /// 为空时保持默认逍遥。
  final String? initialSect;

  @override
  State<JobWudaoPage> createState() => _JobWudaoPageState();
}

class _JobWudaoPageState extends State<JobWudaoPage> {
  /// 当前门派（默认逍遥，对应原型 `wuSect='xiaoyao'`；
  /// 可由 `initialSect` 覆盖，支持跨页定位门派）。
  late JobSect _sect;

  @override
  void initState() {
    super.initState();
    final key = widget.initialSect;
    _sect = (key != null && kJobSects.any((s) => s.key == key))
        ? kJobSects.firstWhere((s) => s.key == key)
        : kJobSects.firstWhere((s) => s.key == 'xiaoyao');
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final schools = wudaoOf(_sect.key);
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
                      crumbLeft: ToolCatalog.jobWudao.crumbRoot,
                      crumbTail: ToolCatalog.jobWudao.crumb.substring(
                        ToolCatalog.jobWudao.crumbRoot.length,
                      ),
                      onCrumbLeftTap: () =>
                          context.go(ToolCatalog.jobWudao.group.hubLocation),
                      title: ToolCatalog.jobWudao.title,
                      subtitle: ToolCatalog.jobWudao.pageSubtitle,
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
                    // 选中门派名 + 定位 tag（wuName · wuType）
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
                    // 流派卡 / 无数据占位
                    if (schools.isEmpty)
                      _WudaoEmpty(sect: _sect)
                    else
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCols = c.maxWidth >= 700;
                          final gap = 16.0;
                          final cardW = twoCols
                              ? (c.maxWidth - gap) / 2
                              : c.maxWidth;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (var si = 0; si < schools.length; si++)
                                SizedBox(
                                  width: cardW,
                                  child: _SchoolCard(
                                    sect: _sect,
                                    school: schools[si],
                                    index: si,
                                    total: schools.length,
                                  ),
                                ),
                            ],
                          );
                        },
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

/// 官网暂未收录该门派武道数据（对应原型无数据占位）。
class _WudaoEmpty extends StatelessWidget {
  const _WudaoEmpty({required this.sect});

  final JobSect sect;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgCard(
      basePadding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(
              '官网资料站暂未收录该门派武道数据',
              style: TextStyle(
                fontFamily: TgFonts.serif,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tg.t2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '武道系统随 2021 年「江湖焕新」资料片上线，覆盖当时九大门派；'
              '恶人谷收录于其上线专题；曼陀山庄与慕容（重制）官网页面暂未提供。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: tg.t3, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一个武道流派卡（`.path-card`）。
class _SchoolCard extends StatelessWidget {
  const _SchoolCard({
    required this.sect,
    required this.school,
    required this.index,
    required this.total,
  });

  final JobSect sect;
  final WudaoSchool school;

  /// 流派序号（1 起）。
  final int index;

  /// 该门派流派总数。
  final int total;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgCard(
      basePadding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // path-head：序号 tile(38) + 流派名
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tg.goldTint(.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tg.goldTint(.28), width: 1),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: TgFonts.serif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tg.gold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.name,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: tg.t1,
                    ),
                  ),
                  Text(
                    '${sect.name} · 流派 ${index + 1} / $total',
                    style: TextStyle(fontSize: 12, color: tg.t3),
                  ),
                ],
              ),
            ],
          ),
          // 流派被动（wd-pd）
          if (school.passive.icon != null ||
              school.passive.name.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PassiveBox(passive: school.passive),
          ],
          // 各重节点（wd-lname + wd-row）
          for (var li = 0; li < school.layers.length; li++) ...[
            _LayerTitle(
              cn: li < kWudaoTierCn.length
                  ? '武道${kWudaoTierCn[li]}'
                  : '武道${li + 1}重',
            ),
            for (final node in school.layers[li].nodes)
              _NodeRow(node: node),
          ],
        ],
      ),
    );
  }
}

/// 流派被动（`.wd-pd`：图标 + 名称 + 描述）。
class _PassiveBox extends StatelessWidget {
  const _PassiveBox({required this.passive});

  final WudaoPassive passive;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tg.tintOf(tg.gold, .04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (passive.icon != null) ...[
            _NodeIcon(path: passive.icon!, size: 38, radius: 8),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '流派被动 · ${passive.name}',
                  style: TextStyle(fontSize: 13, color: tg.gold2),
                ),
                const SizedBox(height: 3),
                Text(
                  passive.desc,
                  style: TextStyle(fontSize: 12, color: tg.t2, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 层标题（`.wd-lname`：武道一重 + 同层择一提示）。
class _LayerTitle extends StatelessWidget {
  const _LayerTitle({required this.cn});

  final String cn;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Text(
            cn,
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 12.5,
              letterSpacing: 1,
              color: tg.t2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '同层择一 · 每个武道 5 级',
            style: TextStyle(fontSize: 10.5, color: tg.t3),
          ),
        ],
      ),
    );
  }
}

/// 一个节点行（`.p-row wd-row`：图标 + 名称 + 效果）。
class _NodeRow extends StatelessWidget {
  const _NodeRow({required this.node});

  final WudaoNode node;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tg.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (node.icon != null)
            _NodeIcon(path: node.icon!, size: 30, radius: 6)
          else
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tg.tintOf(tg.t2, .06),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          const SizedBox(width: 9),
          SizedBox(
            width: 96,
            child: Text(
              node.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tg.t1,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              node.effect,
              style: TextStyle(
                fontSize: 12.5,
                color: tg.t2,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 武道图标（`.wd-ic` / `.wd-pd img`）。
class _NodeIcon extends StatelessWidget {
  const _NodeIcon({required this.path, required this.size, required this.radius});

  final String path;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          color: context.tg.inset,
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
          const SizedBox(height: 8),
          Text(
            '武道数据源自畅游官网资料站门派专题 · 同层择一，实际表现请以游戏内为准',
            style: TextStyle(fontSize: 11.5, color: tg.t3),
          ),
        ],
      ),
    );
  }
}
