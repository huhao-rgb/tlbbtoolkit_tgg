import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme/design_tokens.dart';

/// 响应式卡片内边距：窄屏（移动端，<640）自动把左右内边距收窄到
/// [TgSpacing.cardPaddingMobileH]，提升水平方向的内容容纳；桌面保持 [base] 原值。
///
/// 用法：把卡内 `Padding(padding: X, child: C)` 替换为
/// `TgCardPadding(base: X, child: C)`（背景 / 边框仍覆盖内边距区域，
/// 视觉效果与原 Padding 一致）。
class TgCardPadding extends StatelessWidget {
  const TgCardPadding({super.key, required this.base, required this.child});

  /// 基础内边距（桌面 / 宽屏下原样使用）。
  final EdgeInsets base;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxWidth < 640
            ? math.min(TgSpacing.cardPaddingMobileH, base.horizontal)
            : base.horizontal;
        return Padding(
          padding: EdgeInsets.fromLTRB(h, base.top, h, base.bottom),
          child: child,
        );
      },
    );
  }
}

/// 响应式卡片容器：窄屏（移动端，<640）自动把左右内边距收窄到
/// [TgSpacing.cardPaddingMobileH]，提升水平方向的内容容纳；桌面保持
/// [basePadding] 原值。
///
/// 用法：把卡片 `Container(padding: X, decoration: D, child: C)` 替换为
/// `TgCard(basePadding: X, decoration: D, child: C)`。
class TgCard extends StatelessWidget {
  const TgCard({
    super.key,
    required this.basePadding,
    required this.decoration,
    this.width,
    this.clipBehavior = Clip.none,
    required this.child,
  });

  /// 基础内边距（桌面 / 宽屏下原样使用）。
  final EdgeInsets basePadding;

  final BoxDecoration decoration;

  /// 卡片宽度；null = 不限制（随父级约束 / 内容尺寸，与原 Container 一致）。
  final double? width;

  final Clip clipBehavior;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxWidth < 640
            ? math.min(TgSpacing.cardPaddingMobileH, basePadding.horizontal)
            : basePadding.horizontal;
        return Container(
          width: width,
          padding: EdgeInsets.fromLTRB(
            h,
            basePadding.top,
            h,
            basePadding.bottom,
          ),
          clipBehavior: clipBehavior,
          decoration: decoration,
          child: child,
        );
      },
    );
  }
}
