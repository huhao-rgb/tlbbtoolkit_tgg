import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';

/// 占比条行：左侧 label + 6px 轨道（`tg.inset`）+ 金渐变填充 + 右侧数值。
///
/// 全站多处同款（珍兽 / 账号行情的价位分布与区服分布、珍兽概率条、
/// 门派介绍属性条 …），差异只在 label 宽度 / 对齐、尾部数值与填充色。
class TgBarRow extends StatelessWidget {
  const TgBarRow({
    super.key,
    required this.label,
    required this.widthFactor,
    this.labelWidth = 110,
    this.labelAlign = TextAlign.right,
    this.labelStyle,
    this.trailing,
    this.trailingWidth,
    this.gradient = fillGradient,
    this.barHeight = 6,
    this.bottom = 9,
    this.gap = 10,
  });

  /// 默认填充渐变（原型统一色值）。
  static const LinearGradient fillGradient = LinearGradient(
    colors: [Color(0xFFC9995A), Color(0xFFF2D49B)],
  );

  final String label;

  /// 填充比例（0~1，内部 clamp）。
  final double widthFactor;

  final double labelWidth;
  final TextAlign labelAlign;

  /// label 文字样式；null 用默认（12 / t2 / 字距 .5）。
  final TextStyle? labelStyle;

  /// 右侧尾部内容（数值 / 富文本）；null 时不占位。
  final Widget? trailing;

  /// 尾部固定宽度；null 时按内容自适应。
  final double? trailingWidth;

  final LinearGradient gradient;
  final double barHeight;

  /// 行下间距。
  final double bottom;

  /// label / 轨道 / 尾部之间的横向间距。
  final double gap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              textAlign: labelAlign,
              style:
                  labelStyle ??
                  TextStyle(fontSize: 12, color: tg.t2, letterSpacing: .5),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: barHeight,
                color: tg.inset,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widthFactor.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: gap),
            if (trailingWidth != null)
              SizedBox(width: trailingWidth, child: trailing)
            else
              trailing!,
          ],
        ],
      ),
    );
  }
}
