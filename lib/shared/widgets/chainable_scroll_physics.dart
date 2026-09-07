import 'package:flutter/widgets.dart';

/// 内层滚动「越界转交外层」物理：内层滚动到顶部/底部后，把剩余拖动位移
/// （以及向外滑动的惯性）转交给外层整页滚动，页面得以继续滚动，避免内层
/// 「卡死」在最上/最下。
///
/// Flutter 对任意嵌套的纵向滚动没有自动链式传递，这里通过在
/// [ScrollPhysics.applyPhysicsToUserOffset] 里判断内层是否越界实现手动转交：
/// - 手指下移（offset>0，朝顶部）时内层已到顶 → 把越界部分交给外层（向上滚）；
/// - 手指上移（offset<0，朝底部）时内层已到底 → 把越界部分交给外层（向下滚）；
/// - 未越界时按平台默认物理（Clamping/Bouncing）正常滚动内层。
class ChainableScrollPhysics extends ScrollPhysics {
  const ChainableScrollPhysics({super.parent, required this.outer});

  /// 外层整页滚动位置（内层所在区块的祖先 Scrollable）。
  final ScrollPositionWithSingleContext? outer;

  @override
  ChainableScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      ChainableScrollPhysics(parent: buildParent(ancestor), outer: outer);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final out = outer;
    if (out != null && out.hasPixels) {
      // 朝顶部拖、且会越过内层顶部：内层吸收到顶，剩余转交外层（向上滚）。
      if (offset > 0 && position.pixels - offset < position.minScrollExtent) {
        final accepted = position.pixels - position.minScrollExtent;
        _forwardOuter(out, offset - accepted);
        return accepted;
      }
      // 朝底部拖、且会越过内层底部：内层吸收到底，剩余转交外层（向下滚）。
      if (offset < 0 && position.pixels - offset > position.maxScrollExtent) {
        final accepted = position.pixels - position.maxScrollExtent;
        _forwardOuter(out, offset - accepted);
        return accepted;
      }
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final out = outer;
    if (out != null && out.hasPixels) {
      // 已在顶/底且惯性仍朝外：把惯性转交外层，内层不再动画。
      final atTop = velocity < 0 && position.pixels <= position.minScrollExtent;
      final atBottom = velocity > 0 && position.pixels >= position.maxScrollExtent;
      if (atTop || atBottom) {
        out.goBallistic(velocity);
        return null;
      }
    }
    return super.createBallisticSimulation(position, velocity);
  }

  /// 外层不在拖动活动中，不能走 [ScrollPositionWithSingleContext.applyUserOffset]
  /// （其 `setPixels` 会断言 `activity.isScrolling`）；改用
  /// [ScrollPositionWithSingleContext.jumpTo] 直接移动，并 clamp 到外层边界。
  static void _forwardOuter(ScrollPositionWithSingleContext out, double delta) {
    out.jumpTo((out.pixels - delta).clamp(out.minScrollExtent, out.maxScrollExtent));
  }
}
