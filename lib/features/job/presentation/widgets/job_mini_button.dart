import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

/// 描边小按钮（`.btn btn-sm btn-line`）：32 高 · r9 · 12.5。
///
/// 用于「技能树 / 去加点 / 一键推荐 / 清空」等次级操作；
/// [enabled] 为 false 时半透明禁用（对齐 `.d-ops button:disabled`）。
class JobMiniButton extends StatefulWidget {
  const JobMiniButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.prefix,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  /// 可选前置图标（如五行行的 − / ＋）。
  final Widget? prefix;

  @override
  State<JobMiniButton> createState() => _JobMiniButtonState();
}

class _JobMiniButtonState extends State<JobMiniButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final enabled = widget.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Opacity(
        opacity: enabled ? 1 : .28,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
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
                  color: _hover && enabled ? tg.goldTint(.45) : tg.borderHi,
                  width: 1,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.prefix != null) ...[
                      widget.prefix!,
                      const SizedBox(width: 5),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _hover && enabled ? tg.t1 : tg.t2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
