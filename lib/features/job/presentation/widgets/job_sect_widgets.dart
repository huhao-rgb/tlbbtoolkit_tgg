import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/job_sect.dart';

/// 门派筛选 pill（`.sect`：圆形字徽 + 门派名）。
///
/// 在职业相关二级页（武道 / 技能库 / 神器 / 门派介绍）中复用的门派筛选按钮。
class JobSectPill extends StatefulWidget {
  const JobSectPill({
    super.key,
    required this.sect,
    required this.active,
    required this.onTap,
  });

  final JobSect sect;
  final bool active;
  final VoidCallback onTap;

  @override
  State<JobSectPill> createState() => _JobSectPillState();
}

class _JobSectPillState extends State<JobSectPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final active = widget.active;
    final markC = Color(widget.sect.colorValue);
    final borderC = active
        ? tg.goldTint(.55)
        : (_hover ? tg.goldTint(.45) : tg.borderHi);
    final textC = active ? tg.gold2 : (_hover ? tg.t1 : tg.t2);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: TgRadius.pillShape,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
            decoration: BoxDecoration(
              color: active ? tg.goldTint(.09) : tg.inset2,
              borderRadius: TgRadius.pillShape,
              border: Border.all(color: borderC, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // sect-mark：27 圆字徽（门派色描边 + 文字）
                Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: markC, width: 1),
                  ),
                  child: Text(
                    widget.sect.mark,
                    style: TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: markC,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.sect.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: textC,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 门派定位 tag（如 内功 · 控制）：文字 / 描边 / 底色用门派色。
class JobSectTag extends StatelessWidget {
  const JobSectTag({super.key, required this.sect, this.filled = true});

  final JobSect sect;

  /// 是否带门派色半透明底（原型中武道/技能库带 8% 底；神器/门派介绍透明）。
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = Color(sect.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? c.withValues(alpha: .08) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: c.withValues(alpha: filled ? .4 : .45),
          width: 1,
        ),
      ),
      child: Text(
        sect.type,
        style: TextStyle(fontSize: 11, height: 1.7, color: c),
      ),
    );
  }
}
