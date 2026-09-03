import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';
import 'tg_icon.dart';

/// 弹窗遮罩色（对应原型 `.modal-ov` 深色遮罩）。
const _modalBarrier = Color(0xA807090D);

/// 展示一个居中「天工阁」风格弹窗。
///
/// 使用透明 `Dialog` 外壳（自带 `Material` 上下文，正文文字不会出现
/// 黄色双下划线）+ [TgModalShell] 卡片（`.modal`：r20 · 描边 · 大阴影 ·
/// 最大宽/高 滚动），供套装部件、技能详情等弹窗复用。
Future<void> showTgModal({
  required BuildContext context,
  required Widget child,
  double maxWidth = 460,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: _modalBarrier,
    builder: (_) => TgModalShell(maxWidth: maxWidth, child: child),
  );
}

/// 弹窗卡片外壳（对应原型 `.modal`），宽 [maxWidth] · 高 ≤ 84vh · 内边距 22。
class TgModalShell extends StatelessWidget {
  const TgModalShell({super.key, this.maxWidth = 460, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 弹窗关闭按钮（`.modal-x`：30×30 · r9 · 加强描边 · 小号 ×，居中）。
class TgModalCloseButton extends StatelessWidget {
  const TgModalCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: tg.borderHi, width: 1),
          ),
          // Center + 较小 icon，避免放大/偏移（对应原型 modal-x 14px 居中）
          child: Center(child: TgIcon('x', size: 13, color: tg.t2)),
        ),
      ),
    );
  }
}
