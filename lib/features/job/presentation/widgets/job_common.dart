import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/tg_icon.dart';

/// soul-fx 强调块（`<b>` 标题 + 说明，左侧竖条着色）。
enum JobSoulAccent { gold, blue, green }

/// 小节标题（`.mat-sec h4`：标题 + 右侧分隔线）。
class JobSectionTitle extends StatelessWidget {
  const JobSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: tg.t3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: tg.borderHi)),
      ],
    );
  }
}

/// soul-fx 强调块（对应原型 `.soul-fx`：左竖条 + 淡底 + 金粗标题）。
class JobSoulFx extends StatelessWidget {
  const JobSoulFx({
    super.key,
    required this.title,
    required this.text,
    this.top = 14,
    this.accent = JobSoulAccent.gold,
  });

  final String title;
  final String text;
  final double top;
  final JobSoulAccent accent;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final Color bar;
    final Color bg;
    switch (accent) {
      case JobSoulAccent.gold:
        bar = tg.gold2;
        bg = tg.goldTint(.07);
      case JobSoulAccent.blue:
        bar = tg.blue;
        bg = tg.tintOf(tg.blue, .07);
      case JobSoulAccent.green:
        bar = tg.green;
        bg = tg.tintOf(tg.green, .07);
    }
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        border: Border(left: BorderSide(color: bar, width: 3)),
      ),
      child: Text.rich(
        TextSpan(
          text: '$title · ',
          style: TextStyle(
            fontSize: 12.5,
            color: tg.gold2,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: text,
              style: TextStyle(
                fontSize: 12.5,
                color: tg.t2,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}

/// mat-item 数据（徽章 + 标签 + 数值）。
class JobMatItem {
  const JobMatItem({
    required this.label,
    required this.value,
    required this.badge,
  });

  final String label;
  final String value;
  final String badge;
}

/// mat-row：flex 网格（基础属性 / 门派特色）。
class JobMatRow extends StatelessWidget {
  const JobMatRow({super.key, required this.items, this.compact = false});

  final List<JobMatItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final cols = compact
            ? 1
            : (((c.maxWidth + gap) / 220).floor()).clamp(1, items.length);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final it in items)
              SizedBox(
                width: w,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: tg.inset,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: tg.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      // mat-badge：金序号
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tg.goldTint(.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tg.goldTint(.28), width: 1),
                        ),
                        child: Text(
                          it.badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tg.gold2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              it.label,
                              style: TextStyle(fontSize: 12, color: tg.t2),
                            ),
                            Text(
                              it.value,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: tg.t1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 页脚注（`.note`：inset 底 + info 图标）。
class JobNote extends StatelessWidget {
  const JobNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: tg.inset,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tg.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TgIcon('info', size: 15, color: tg.goldDp),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: tg.t3, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}
