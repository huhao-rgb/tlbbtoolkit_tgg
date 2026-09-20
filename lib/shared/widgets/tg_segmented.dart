import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// 分段按钮组（对应原型 `.lv-seg`）：inset 底 + 3px 内距 + 若干按钮。
///
/// 项目统一用它替代 Material `SegmentedButton` / `TabBar` 这类「少量互斥选项」
/// 切换（档位、主题模式等）：
/// - 外框：inset 底 · r9 · 1px 加强描边 · 内距 3；
/// - 按钮：r6.5 · 水平内距 9 / 垂直 3.5；
/// - 选中：金 .14 底 + 金 .4 描边 + gold2 文字（600）；未选：透明底 + t3 文字。
class TgSegmented extends StatelessWidget {
  const TgSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelect,
    this.expand = false,
  });

  /// 选项文案（同时作为选中值回传 `onSelect`）。
  final List<String> values;

  /// 当前选中值。
  final String selected;

  final ValueChanged<String> onSelect;

  /// true = 各按钮等分占满可用宽度（窄屏 / 卡片内整行）；false = 自适应内容宽。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(TgRadius.s9),
        border: Border.all(color: tg.borderHi, width: 1),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final v in values)
            if (expand)
              Expanded(
                child: TgSegmentedButton(
                  label: v,
                  active: v == selected,
                  onTap: () => onSelect(v),
                ),
              )
            else
              TgSegmentedButton(
                label: v,
                active: v == selected,
                onTap: () => onSelect(v),
              ),
        ],
      ),
    );
  }
}

/// 分段按钮组的单个按钮（也可单独使用，如档位 pill）。
class TgSegmentedButton extends StatelessWidget {
  const TgSegmentedButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.5),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: active ? tg.goldTint(.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(6.5),
            border: active
                ? Border.all(color: tg.goldTint(.4), width: 1)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TgType.caption.copyWith(
              color: active ? tg.gold2 : tg.t3,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
