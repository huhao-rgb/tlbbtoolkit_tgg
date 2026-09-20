import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// 自定义开关（对应原型 `.switch`）：46×26 轨道 · 20 圆钮 · 金渐变选中。
///
/// 项目统一用它替代 Material `Switch` / `SwitchListTile`，保证两端与原型观感一致：
/// - 轨道：46×26 · 胶囊 · 内距 2（选中 = 金 .14 底 + 金描边，未选 = inset2 底 + 加强描边）；
/// - 圆钮：20 · 圆形（选中 = 金渐变，未选 = t3），左/右切换 220ms easeOut；
/// - 可选文字 label（[showLabel] 为 true 时显示在轨道右侧）。
class TgSwitch extends StatelessWidget {
  const TgSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '',
    this.showLabel = false,
    this.enabled = true,
  });

  final bool value;

  /// 轨道右侧文字（仅 [showLabel] 为 true 时渲染）。
  final String label;
  final bool showLabel;

  /// 禁用时整体降不透明度且不响应点击。
  final bool enabled;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 轨道：46×26 · 内边距2（+边框1 各侧）· 圆钮 20
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 46,
              height: 26,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? tg.goldTint(.14) : tg.inset2,
                borderRadius: TgRadius.pillShape,
                border: Border.all(
                  color: value ? tg.gold : tg.borderHi,
                  width: 1,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: value ? tg.gradGold : null,
                    color: value ? null : tg.t3,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (showLabel && label.isNotEmpty) ...[
              const SizedBox(width: TgSpacing.s9),
              Text(
                label,
                style: TgType.label.copyWith(color: value ? tg.gold2 : tg.t2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 开关行（对应原型 `.switch-row`）：左侧文案，右侧 [TgSwitch]。
///
/// 两种排版：
/// - 只给 [label]（+ 可选 [hint]，接在主标题后，t3）：单行文案，用于表单行；
/// - 给 [subtitle]：主标题 [label]（14.5/500 t1）+ 次行说明（12 t3），
///   用于设置项这类「标题 + 说明」的列表行。
class TgSwitchRow extends StatelessWidget {
  const TgSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.subtitle,
    this.switchLabel = '',
    this.showSwitchLabel = false,
    this.enabled = true,
  });

  final String label;

  /// 单行排版下接在主标题后的补充说明（t3）。
  final String hint;

  /// 次行说明；非空时改用「主标题 + 说明」两行排版。
  final String? subtitle;

  final String switchLabel;
  final bool showSwitchLabel;
  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final title = switch (subtitle) {
      null => Text.rich(
        TextSpan(
          text: label,
          style: TgType.label.copyWith(color: tg.t2),
          children: [
            TextSpan(
              text: hint,
              style: TgType.label.copyWith(color: tg.t3),
            ),
          ],
        ),
      ),
      final sub => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TgType.cardTitle.copyWith(color: tg.t1)),
          const SizedBox(height: 3),
          Text(sub, style: TgType.caption.copyWith(color: tg.t3)),
        ],
      ),
    };

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: TgSpacing.s12),
        TgSwitch(
          key: Key('tg-switch-$label'),
          label: switchLabel,
          showLabel: showSwitchLabel,
          value: value,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
