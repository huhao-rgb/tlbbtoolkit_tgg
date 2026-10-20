import 'package:flutter/widgets.dart';

import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';

/// 吸顶内容的「顶栏遮挡区」：放在滚动体最前面的透明 pinned 头。
///
/// 悬浮毛玻璃顶栏由 shell 叠在页面之上（高 [Breakpoints.topbarOverlayHeight]），
/// 而 [SliverPersistentHeader] 一律吸附在滚动视口顶部（y = 0），那里正好被
/// 顶栏盖住。在滚动体最前面放一个等高的**透明** pinned 头之后，后续 pinned
/// 头会因 pinned 遮挡的叠加而停在顶栏下沿（y = 顶栏高度），内容仍然能从
/// 玻璃下方滑过（占位头不绘制任何东西）。
///
/// 用法：作为 `CustomScrollView.slivers` 的第一项，并把页面内边距的 `top`
/// 减去同样的高度，初始排版保持不变。
class SliverTopbarSpacer extends StatelessWidget {
  const SliverTopbarSpacer({
    super.key,
    this.height = Breakpoints.topbarOverlayHeight,
  });

  /// 占位高度，默认等于悬浮顶栏高度。
  final double height;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SpacerDelegate(height),
    );
  }
}

class _SpacerDelegate extends SliverPersistentHeaderDelegate {
  const _SpacerDelegate(this.height);

  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 透明占位：不绘制，也不参与命中测试（不会挡住顶栏按钮或内容点击）。
    return SizedBox(width: double.infinity, height: height);
  }

  @override
  bool shouldRebuild(_SpacerDelegate oldDelegate) =>
      oldDelegate.height != height;
}
