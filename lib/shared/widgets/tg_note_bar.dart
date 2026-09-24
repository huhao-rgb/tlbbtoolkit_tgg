import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';

/// note 条配色：
/// - [gold]：金色淡底（`gold(.05)` 底 + `gold(.2)` 描边 + `gold2` 图标），
///   用于规则 / 数据来源等强调型说明；
/// - [plain]：中性 inset 底（`tg.inset` 底 + `tg.border` 描边 + `goldDp` 图标），
///   用于公式 / 设置等一般性说明；
/// - [danger]：红色淡底（`red(.08)` 底 + `red(.3)` 描边 + `red` 图标），
///   用于「请勿…」类警示。
enum TgNoteAccent { gold, plain, danger }

/// 说明 note 条（原型 `.note`）：`info` 图标 + 说明文本。
///
/// [text] 与 [child] 二选一：纯文本传 [text]（按 [accent] 套默认排版），
/// 需要局部加粗 / 高亮时传 [child]（自行控制 `Text.rich` 样式）。
class TgNoteBar extends StatelessWidget {
  const TgNoteBar({
    super.key,
    this.text,
    this.child,
    this.accent = TgNoteAccent.gold,
    this.icon = 'info',
  }) : assert(text != null || child != null, 'text / child 至少提供一个');

  /// 纯文本内容（与 [child] 二选一）。
  final String? text;

  /// 自定义内容（与 [text] 二选一，如富文本说明）。
  final Widget? child;

  final TgNoteAccent accent;

  /// 左侧图标资产名（见 `TgIcon._paths`）。
  final String icon;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final gold = accent == TgNoteAccent.gold;
    final plain = accent == TgNoteAccent.plain;
    final bg = switch (accent) {
      TgNoteAccent.gold => tg.goldTint(.05),
      TgNoteAccent.plain => tg.inset,
      TgNoteAccent.danger => tg.tintOf(tg.red, .08),
    };
    final border = switch (accent) {
      TgNoteAccent.gold => tg.goldTint(.2),
      TgNoteAccent.plain => tg.border,
      TgNoteAccent.danger => tg.tintOf(tg.red, .3),
    };
    final iconColor = switch (accent) {
      TgNoteAccent.gold => tg.gold2,
      TgNoteAccent.plain => tg.goldDp,
      TgNoteAccent.danger => tg.red,
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 13, vertical: plain ? 11 : 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TgRadius.lg),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: TgIcon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child:
                child ??
                Text(
                  text!,
                  style: gold
                      ? TextStyle(
                          fontSize: 12.5,
                          color: tg.t2,
                          height: 1.7,
                          letterSpacing: .2,
                        )
                      : TgType.note.copyWith(color: tg.t3, letterSpacing: 0),
                ),
          ),
        ],
      ),
    );
  }
}
