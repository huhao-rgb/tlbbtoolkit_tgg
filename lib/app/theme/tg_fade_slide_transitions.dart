import 'package:flutter/material.dart';

/// 路由 push / pop 转场 —— 还原原型 `.view.active` 的 `fadein`：
/// 新页面 opacity 0→1 · translateY 8px→0 · ease。
///
/// 原型切换时旧视图立即隐藏，新视图在干净背景上淡入。因此这里让「被覆盖
/// 的底层页」在切换一开始就直接透明（secondaryAnimation>0 即隐藏，只有
/// 完全处于顶层才显示），顶层新页单独淡入上移 —— 任何时刻都只有一页可见，
/// 杜绝两页半透明叠加产生的叠影。
class TgFadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const TgFadeSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.ease,
      reverseCurve: Curves.ease,
    );

    return AnimatedBuilder(
      animation: secondaryAnimation,
      // 内层（本路由自身入场/退场动画）作为独立 subtree，避免随底层显隐重建。
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            // 0.012 ≈ 页面高度 700px 时约 8.4px，接近原型固定 8px
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
      builder: (context, inner) {
        // 上方只要有其它路由（被覆盖中 / 返回未完全露出），底层一律透明；
        // 仅当完全处于顶层（secondaryAnimation == 0）时才显示。
        final covered = secondaryAnimation.value > 0.0;
        return Opacity(opacity: covered ? 0.0 : 1.0, child: inner);
      },
    );
  }
}
