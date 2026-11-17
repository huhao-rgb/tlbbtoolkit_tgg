import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/features/job/domain/job_wudao.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_modal.dart';

/// 节点卡尺寸与间距（与游戏内武道界面同构：每重 4 行、最多 3 列）。
const double _nodeW = 208;
const double _nodeH = 92;
const double _gapX = 22;
const double _gapY = 54;

/// 打开「武道树状关系」弹窗。
///
/// 一个「重」就是一张技能树：节点按 [WudaoLayer.rows] 分行排布，
/// [WudaoLayer.edges] 里的关系用折线连起来，尽量还原游戏内武道界面的样子。
Future<void> showWudaoTreeDialog({
  required BuildContext context,
  required String sectName,
  required WudaoSchool school,
  required List<String> tierNames,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xA807090D),
    builder: (_) => _WudaoTreeDialog(
      sectName: sectName,
      school: school,
      tierNames: tierNames,
    ),
  );
}

class _WudaoTreeDialog extends StatefulWidget {
  const _WudaoTreeDialog({
    required this.sectName,
    required this.school,
    required this.tierNames,
  });

  final String sectName;
  final WudaoSchool school;
  final List<String> tierNames;

  @override
  State<_WudaoTreeDialog> createState() => _WudaoTreeDialogState();
}

class _WudaoTreeDialogState extends State<_WudaoTreeDialog> {
  int _layer = 0;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final layers = widget.school.layers;
    final layer = layers.isEmpty
        ? null
        : layers[math.min(_layer, layers.length - 1)];
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 940,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tg.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tg.borderHi, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 70,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(tg),
              if (layers.length > 1) _tierChips(tg, layers.length),
              Divider(height: 1, thickness: 1, color: tg.border),
              Expanded(
                child: layer == null
                    ? Center(
                        child: Text(
                          '该流派暂无节点',
                          style: TextStyle(fontSize: 13, color: tg.t3),
                        ),
                      )
                    : _TreeCanvas(layer: layer),
              ),
              _foot(tg, layer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _head(TgColors tg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.school.name} · 树状关系',
                  style: TextStyle(
                    fontFamily: TgFonts.serif,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                    color: tg.t1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.sectName} · 流派 ${widget.school.name} · '
                  '共 ${widget.school.layers.length} 重',
                  style: TextStyle(fontSize: 12, color: tg.t3),
                ),
              ],
            ),
          ),
          TgModalCloseButton(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _tierChips(TgColors tg, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < count; i++)
            _TierChip(
              label: i < widget.tierNames.length
                  ? '武道${widget.tierNames[i]}'
                  : '武道${i + 1}重',
              selected: i == _layer,
              onTap: () => setState(() => _layer = i),
            ),
        ],
      ),
    );
  }

  Widget _foot(TgColors tg, WudaoLayer? layer) {
    final edges = layer?.edges?.length ?? 0;
    final hint = edges == 0
        ? '该重界面上没有连线（节点同层并列）'
        : '连线为游戏内武道界面中的关联路径（同重内的前置关系）';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tg.border, width: 1)),
      ),
      child: Text(hint, style: TextStyle(fontSize: 11.5, color: tg.t3)),
    );
  }
}

/// 一重的小标签（`.pill` 风格）。
class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? tg.goldTint(.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? tg.goldTint(.45) : tg.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: selected ? tg.gold2 : tg.t2,
            ),
          ),
        ),
      ),
    );
  }
}

/// 树画布：节点卡 + 连线（可横向滚动，窄屏也不压缩字号）。
class _TreeCanvas extends StatelessWidget {
  const _TreeCanvas({required this.layer});

  final WudaoLayer layer;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final layout = _TreeLayout.of(layer);
    final canvas = SizedBox(
      width: layout.size.width,
      height: layout.size.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TreePainter(
                rects: layout.rects,
                edges: layer.edges ?? const [],
                color: tg.goldTint(.68),
              ),
            ),
          ),
          for (final entry in layout.rects.entries)
            Positioned(
              left: entry.value.left,
              top: entry.value.top,
              width: _nodeW,
              height: _nodeH,
              child: _TreeNodeCard(node: layer.nodes[entry.key]),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final inner = Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: canvas,
        );
        if (c.maxWidth >= layout.size.width + 44) {
          return SingleChildScrollView(
            child: Align(alignment: Alignment.topCenter, child: inner),
          );
        }
        // 窄屏：横向滚动，避免卡片被压扁到看不清。
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: inner,
          ),
        );
      },
    );
  }
}

/// 树里的一个节点卡（图标 + 名称 + 效果摘要）。
class _TreeNodeCard extends StatelessWidget {
  const _TreeNodeCard({required this.node});

  final WudaoNode node;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Tooltip(
      message: '${node.name}\n${node.effect}',
      waitDuration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: tg.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tg.borderHi, width: 1),
      ),
      textStyle: TextStyle(fontSize: 12, height: 1.5, color: tg.t2),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: tg.inset,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tg.borderHi, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _icon(tg),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tg.t1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(
                      node.effect,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: tg.t3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(TgColors tg) {
    final size = 34.0;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tg.inset2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tg.border, width: 1),
      ),
    );
    if (node.icon == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.asset(
        node.icon!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// 连线画家：同列直连，跨列走「侧出 → 横移 → 下落」的折线（与游戏内一致）。
class _TreePainter extends CustomPainter {
  const _TreePainter({
    required this.rects,
    required this.edges,
    required this.color,
  });

  final Map<int, Rect> rects;
  final List<List<int>> edges;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final edge in edges) {
      if (edge.length != 2) continue;
      final p = rects[edge[0]];
      final c = rects[edge[1]];
      if (p == null || c == null) continue;
      final path = Path();
      if ((p.center.dx - c.center.dx).abs() < 1.5) {
        // 正上正下：一条竖线。
        path
          ..moveTo(p.center.dx, p.bottom)
          ..lineTo(c.center.dx, c.top);
      } else {
        // 侧出：从父卡右下/左下角附近横移到子卡中心，再垂直落到子卡顶部。
        final outY = p.top + _nodeH * .46;
        final x0 = c.center.dx > p.center.dx ? p.right : p.left;
        path
          ..moveTo(x0, outY)
          ..lineTo(c.center.dx, outY)
          ..lineTo(c.center.dx, c.top);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.rects != rects || old.edges != edges || old.color != color;
}

/// 一重节点的行列排布（从 `rows` 推导坐标）。
class _TreeLayout {
  _TreeLayout(this.rects, this.size);

  final Map<int, Rect> rects;
  final Size size;

  factory _TreeLayout.of(WudaoLayer layer) {
    final n = layer.nodes.length;
    final rowSizes = _rowSizes(layer, n);
    final columns = rowSizes.fold<int>(1, math.max);

    final rows = <List<int>>[];
    var idx = 0;
    for (final size in rowSizes) {
      final take = math.min(size, n - idx);
      if (take <= 0) break;
      rows.add([for (var i = 0; i < take; i++) idx++]);
    }
    // rows 之和小于节点数时，余下的按 3 列补行，保证一个节点都不丢。
    while (idx < n) {
      final take = math.min(columns, n - idx);
      rows.add([for (var i = 0; i < take; i++) idx++]);
    }

    final rects = <int, Rect>{};
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final cols = _columnsFor(row.length, columns);
      for (var i = 0; i < row.length; i++) {
        rects[row[i]] = Rect.fromLTWH(
          cols[i] * (_nodeW + _gapX),
          r * (_nodeH + _gapY),
          _nodeW,
          _nodeH,
        );
      }
    }
    final rowCount = rects.isEmpty
        ? 0
        : (rects.values.map((r) => r.top).reduce(math.max) ~/
                  (_nodeH + _gapY)) +
              1;
    return _TreeLayout(
      rects,
      Size(
        columns * _nodeW + (columns - 1) * _gapX,
        rowCount == 0 ? 0 : rowCount * _nodeH + (rowCount - 1) * _gapY,
      ),
    );
  }

  /// `rows` 合法（均为正数且合计不超过节点数）时直接用，否则按 3 列切。
  static List<int> _rowSizes(WudaoLayer layer, int n) {
    final rows = layer.rows;
    if (rows != null &&
        rows.isNotEmpty &&
        rows.every((v) => v > 0) &&
        rows.reduce((a, b) => a + b) <= n) {
      return rows;
    }
    return [for (var i = 0; i < n; i += 3) math.min(3, n - i)];
  }

  /// 一行的列位：满列时依次排开；少一张时两端对齐（2 张 → 左右两列，同游戏内）。
  static List<int> _columnsFor(int count, int columns) {
    if (count >= columns || columns <= 1) {
      return [for (var i = 0; i < count; i++) i];
    }
    if (count == 1) return [columns ~/ 2];
    return [
      for (var i = 0; i < count; i++) ((columns - 1) * i / (count - 1)).round(),
    ];
  }
}
