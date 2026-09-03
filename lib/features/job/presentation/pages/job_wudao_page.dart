import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/tools/tool_catalog.dart';
import '../../../../shared/widgets/page_head.dart';
import '../../../../shared/widgets/tg_icon.dart';
import '../../../../shared/widgets/tg_modal.dart';
import '../../../../shared/widgets/tg_page_entrance.dart';
import '../../domain/job_sect.dart';
import '../../domain/job_wudao.dart';
import '../widgets/job_sect_widgets.dart';

/// 职业武道（对应原型 `v-class-wudao`）。
///
/// 门派筛选（`.sect-row`）+ 选中门派名与定位 tag +
/// 攻伐/御守两条路线卡（`.wudao-grid`）；每重一行「一重~四重」，
/// 点行内「技能树」打开该重技能树弹窗（wudaoModal）。
class JobWudaoPage extends StatefulWidget {
  const JobWudaoPage({super.key});

  @override
  State<JobWudaoPage> createState() => _JobWudaoPageState();
}

class _JobWudaoPageState extends State<JobWudaoPage> {
  /// 当前门派（默认逍遥，对应原型 `wuSect='xiaoyao'`）。
  JobSect _sect = kJobSects.firstWhere((s) => s.key == 'xiaoyao');

  void _openTree(int pathIndex, int tierIndex) {
    final path = kWudaoPaths[pathIndex];
    final tier = path.tiers[tierIndex];
    // 技能树 viewBox 宽 600，放宽弹窗保证树清晰可读
    showTgModal(
      context: context,
      maxWidth: 560,
      child: _WudaoDialog(
        pathIndex: pathIndex,
        pathName: path.name,
        tierName: tier.name,
        tierCn: kWudaoTierCn[tierIndex],
        nodes: tier.tree,
      ),
    );
  }

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
                    // 武道路线双卡（wudao-grid：≥1024 双列，否则单列）
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
                            for (var pi = 0; pi < kWudaoPaths.length; pi++)
                              SizedBox(
                                width: cardW,
                                child: _PathCard(
                                  path: kWudaoPaths[pi],
                                  onTree: (ti) => _openTree(pi, ti),
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

/// 一条武道路线卡（`.path-card`）。
class _PathCard extends StatelessWidget {
  const _PathCard({required this.path, required this.onTree});

  final WudaoPath path;

  /// 点某重「技能树」（参数 = 重序号 0~3）。
  final ValueChanged<int> onTree;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: TgRadius.card,
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // path-head：金 tile(38) + serif 路线名
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tg.goldTint(.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tg.goldTint(.28), width: 1),
                ),
                child: Center(
                  child: TgIcon(path.icon, size: 18, color: tg.gold),
                ),
              ),
              const SizedBox(width: 11),
              Text(
                path.name,
                style: TextStyle(
                  fontFamily: TgFonts.serif,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: tg.t1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // path-sub
          Text(path.sub, style: TextStyle(fontSize: 12, color: tg.t3)),
          const SizedBox(height: 15),
          // path-rows
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tg.border, width: 1)),
            ),
            child: Column(
              children: [
                for (var ti = 0; ti < path.tiers.length; ti++)
                  _PathRow(
                    cn: kWudaoTierCn[ti],
                    tier: path.tiers[ti],
                    isLast: ti == path.tiers.length - 1,
                    onTree: () => onTree(ti),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // path-foot：推荐度 + ★ + 去加点
          Row(
            children: [
              Text('推荐度', style: TextStyle(fontSize: 12, color: tg.t3)),
              const SizedBox(width: 9),
              Text(
                List.filled(path.rec, '★').join() +
                    List.filled(5 - path.rec, '☆').join(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  color: tg.gold,
                ),
              ),
              const Spacer(),
              _LineMiniButton(
                label: '去加点',
                onTap: () => context.go(ToolCatalog.jobPoint.location),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 武道路线中的一「重」行（`.p-row`）。
class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.cn,
    required this.tier,
    required this.isLast,
    required this.onTree,
  });

  final String cn;
  final WudaoTier tier;

  /// 是否最后一行（原型 `.p-row:last-child` 无下边框）。
  final bool isLast;
  final VoidCallback onTree;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.5),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: tg.border, width: 1)),
      ),
      child: Row(
        children: [
          // p-lv：一重/二重…（金色 · 38px）
          SizedBox(
            width: 38,
            child: Text(
              cn,
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1,
                color: tg.gold2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // p-name
          Text(
            tier.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tg.t1,
            ),
          ),
          const Spacer(),
          // p-eff（tabular 数值）
          Text(
            tier.effect,
            style: TextStyle(
              fontSize: 12.5,
              color: tg.t2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          // 技能树按钮
          _LineMiniButton(label: '技能树', onTap: onTree),
        ],
      ),
    );
  }
}

/// 描边小按钮（`.btn btn-sm btn-line`）：32 高 · r9 · 12.5。
class _LineMiniButton extends StatefulWidget {
  const _LineMiniButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_LineMiniButton> createState() => _LineMiniButtonState();
}

class _LineMiniButtonState extends State<_LineMiniButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(9),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _hover ? tg.goldTint(.45) : tg.borderHi,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _hover ? tg.t1 : tg.t2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 技能树弹窗（对应原型 wudaoModal）。
class _WudaoDialog extends StatelessWidget {
  const _WudaoDialog({
    required this.pathIndex,
    required this.pathName,
    required this.tierName,
    required this.tierCn,
    required this.nodes,
  });

  /// 0=攻伐（红系）/ 1=御守（蓝系）。
  final int pathIndex;
  final String pathName;
  final String tierName;
  final String tierCn;
  final List<WudaoNode> nodes;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final attack = pathIndex == 0;
    // tile 配色：攻伐=红 / 御守=蓝
    final base = attack ? const Color(0xFFFF7069) : const Color(0xFF5B9BFF);
    final charText = attack ? const Color(0xFFFFC9C5) : const Color(0xFFBFDCFF);
    final head = Row(
      children: [
        // tile 40：攻 / 御 字徽（径向渐变）
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.36, -0.44),
              colors: [
                base.withValues(alpha: .4),
                Colors.white.withValues(alpha: .03),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: base.withValues(alpha: .45), width: 1),
          ),
          child: Text(
            attack ? '攻' : '御',
            style: TextStyle(
              fontFamily: TgFonts.serif,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: charText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '武道 · $tierName',
                style: TextStyle(
                  fontFamily: TgFonts.serif,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: tg.t1,
                ),
              ),
              const SizedBox(height: 4),
              // tag-gold：攻伐之道 · 一重
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tg.goldTint(.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tg.goldTint(.4), width: 1),
                ),
                child: Text(
                  '$pathName · $tierCn',
                  style: TextStyle(fontSize: 11, height: 1.7, color: tg.gold2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TgModalCloseButton(onTap: () => Navigator.pop(context)),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        const SizedBox(height: 14),
        // 技能树（等比缩放，按 600×268 逻辑坐标绘制）
        _SkillTree(nodes: nodes),
        const SizedBox(height: 14),
        // calc-note
        _calcNote(context),
      ],
    );
  }

  Widget _calcNote(BuildContext context) {
    final tg = context.tg;
    return Text.rich(
      TextSpan(
        text: '※ 解锁顺序：',
        style: TextStyle(fontSize: 11.5, color: tg.t3, height: 1.6),
        children: [
          TextSpan(
            text: '核心节点',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: tg.gold2,
            ),
          ),
          TextSpan(
            text: ' → 两大分支 → 各分支两重进阶；重数提升后前置节点效果保留。',
            style: TextStyle(fontSize: 11.5, color: tg.t3),
          ),
        ],
      ),
    );
  }
}

/// 技能树 7 节点布局（viewBox 600×268）。
const List<List<double>> _kTreePos = [
  [215, 14, 170, 48], // 0 核心
  [75, 102, 180, 48], // 1
  [345, 102, 180, 48], // 2
  [10, 204, 150, 52], // 3
  [155, 204, 150, 52], // 4
  [295, 204, 150, 52], // 5
  [440, 204, 150, 52], // 6
];

/// 技能树连线（父 → 子）。
const List<List<int>> _kTreeEdges = [
  [0, 1],
  [0, 2],
  [1, 3],
  [1, 4],
  [2, 5],
  [2, 6],
];

/// 等比缩放的技能树（对应原型 `treeSVG`）。
class _SkillTree extends StatelessWidget {
  const _SkillTree({required this.nodes});

  final List<WudaoNode> nodes;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return AspectRatio(
      aspectRatio: 600 / 268,
      child: LayoutBuilder(
        builder: (context, c) {
          final scaleX = c.maxWidth / 600;
          final scaleY = c.maxHeight / 268;
          return Stack(
            children: [
              // 连线
              Positioned.fill(
                child: CustomPaint(
                  painter: _TreeLinePainter(
                    edges: _kTreeEdges,
                    pos: _kTreePos,
                    color: tg.borderHi,
                    scaleX: scaleX,
                    scaleY: scaleY,
                  ),
                ),
              ),
              // 节点
              for (var i = 0; i < nodes.length; i++)
                Positioned(
                  left: _kTreePos[i][0] * scaleX,
                  top: _kTreePos[i][1] * scaleY,
                  width: _kTreePos[i][2] * scaleX,
                  height: _kTreePos[i][3] * scaleY,
                  child: _TreeNode(node: nodes[i], root: i == 0),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 技能树连线（贝塞尔曲线）。
class _TreeLinePainter extends CustomPainter {
  const _TreeLinePainter({
    required this.edges,
    required this.pos,
    required this.color,
    required this.scaleX,
    required this.scaleY,
  });

  final List<List<int>> edges;
  final List<List<double>> pos;
  final Color color;
  final double scaleX;
  final double scaleY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final e in edges) {
      final a = pos[e[0]];
      final b = pos[e[1]];
      final ax = (a[0] + a[2] / 2) * scaleX;
      final ay = (a[1] + a[3]) * scaleY;
      final bx = (b[0] + b[2] / 2) * scaleX;
      final by = b[1] * scaleY;
      final path = Path()
        ..moveTo(ax, ay)
        ..cubicTo(ax, ay + 28 * scaleY, bx, by - 28 * scaleY, bx, by);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) =>
      old.color != color || old.scaleX != scaleX || old.scaleY != scaleY;
}

/// 单个技能树节点盒（`.tnode`，root 用深金描边）。
class _TreeNode extends StatelessWidget {
  const _TreeNode({required this.node, required this.root});

  final WudaoNode node;
  final bool root;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: tg.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: root ? tg.goldDp : tg.borderHi, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.name,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tg.t1,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            node.effect,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(fontSize: 11, color: tg.t2, height: 1.3),
          ),
        ],
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
