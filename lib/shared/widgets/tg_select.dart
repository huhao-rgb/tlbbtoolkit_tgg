import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// 通用下拉筛选（对应原型 `pm-f-item select` 的 Flutter 实现）。
///
/// 自绘「标签 + 弹出菜单」组合：固定宽下拉框 · 9px 圆角 · 底部三角箭头
/// （内联自绘），供各类列表/筛选页复用：
/// - `value` 为当前选中文本，为空时显示 `hint`；
/// - `options` 为 `(value, label)` 元组列表，弹出项点击回传 `value`；
/// - 首项固定为 `hint`（value 为空串），与「未选择」语义一致。
class TgSelect extends StatelessWidget {
  const TgSelect({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.width = 150,
  });

  final String label;

  /// 当前选中值（显示文本）；为空显示 hint。
  final String value;
  final String hint;

  /// (value, label)。
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  /// 下拉框固定宽（对齐原生 select 稳定宽度）。
  final double width;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final text = value.isEmpty ? hint : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: tg.t3, letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          key: ValueKey('tg-select-$label'),
          tooltip: '',
          onSelected: onChanged,
          position: PopupMenuPosition.under,
          color: tg.inset2,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: tg.borderHi),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: '',
              height: 34,
              child: Text(hint, style: TextStyle(fontSize: 12.5, color: tg.t2)),
            ),
            for (final (v, l) in options)
              PopupMenuItem<String>(
                value: v,
                height: 34,
                child: Text(l, style: TextStyle(fontSize: 12.5, color: tg.t1)),
              ),
          ],
          child: Container(
            width: width,
            height: 34,
            padding: const EdgeInsets.only(left: 12, right: 10),
            decoration: BoxDecoration(
              color: tg.inset,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: tg.border, width: 1),
            ),
            child: Row(
              children: [
                // 文本占满中间空间（左对齐），箭头固定贴右缘。
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: tg.t1),
                  ),
                ),
                const SizedBox(width: 8),
                _Chevron(color: tg.t3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 下拉右箭头（内联三角，对应原型 select 的箭头 SVG）。
class _Chevron extends StatelessWidget {
  const _Chevron({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(10, 6),
      painter: _ChevronPainter(color),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final p = Path()
      ..moveTo(1, 1)
      ..lineTo(size.width / 2, size.height - 1)
      ..lineTo(size.width - 1, 1);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
