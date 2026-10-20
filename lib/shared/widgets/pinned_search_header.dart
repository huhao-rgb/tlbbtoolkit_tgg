import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_text_field.dart';

/// 搜索框区域的总高度：上留白 8 + 搜索框 38 + 底部留白 6。
const double kPinnedSearchHeaderExtent = 8 + 38 + 6;

/// 吸顶搜索框（行情类页面的「在售明细」表头）。
///
/// 用法：把本组件放进 `SliverPersistentHeader(pinned: true)`，并让滚动体
/// 最前面带一个 [SliverTopbarSpacer] —— 这样它会停在悬浮顶栏下沿而不是被
/// 顶栏盖住。
///
/// 外观与行为：
/// - 未吸顶时与普通内容无异；
/// - 吸顶后（`shrinkOffset > 0`）用卡片同底色压住下方滚过的行，并在底边叠
///   1px 分隔线（叠在底部留白里，不额外占高度）；
/// - 横向内边距由外层 `SliverPadding`（卡片内距）负责，这里只管纵向节奏。
class PinnedSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const PinnedSearchHeaderDelegate({
    required this.background,
    required this.borderColor,
    required this.child,
    this.extent = kPinnedSearchHeaderExtent,
    this.topGap = 8,
  });

  final Color background;
  final Color borderColor;
  final Widget child;

  /// 头部区域总高度（默认 [kPinnedSearchHeaderExtent]）。
  final double extent;

  /// 内容上方留白。
  final double topGap;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final stuck = shrinkOffset > 0;
    return SizedBox(
      height: extent,
      child: ColoredBox(
        color: background,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topGap),
              child: child,
            ),
            if (stuck)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 1,
                child: ColoredBox(color: borderColor),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(PinnedSearchHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent ||
      oldDelegate.topGap != topGap ||
      oldDelegate.background != background ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.child != child;
}

/// 行情列表页通用的明细搜索框（[TgTextField] + 放大镜 + 「清空」后缀）。
///
/// 输入变化即时回调 [onKw]（调用方自行防抖）；关键字非空时右侧出现「清空」。
class TgSearchBox extends StatefulWidget {
  const TgSearchBox({
    super.key,
    required this.hintText,
    required this.kw,
    required this.onKw,
    required this.onClear,
    this.fontSize = 12.5,
    this.height = 38,
  });

  final String hintText;

  /// 当前已生效的关键字（决定是否显示「清空」）。
  final String kw;
  final ValueChanged<String> onKw;
  final VoidCallback onClear;
  final double fontSize;
  final double height;

  @override
  State<TgSearchBox> createState() => _TgSearchBoxState();
}

class _TgSearchBoxState extends State<TgSearchBox> {
  late final TextEditingController _c = TextEditingController(text: widget.kw);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return TgTextField(
      controller: _c,
      hintText: widget.hintText,
      prefixIcon: 'search',
      fontSize: widget.fontSize,
      height: widget.height,
      horizontalPadding: 12,
      radius: BorderRadius.circular(9),
      onChanged: widget.onKw,
      suffix: widget.kw.isEmpty
          ? null
          : InkWell(
              onTap: () {
                _c.clear();
                widget.onClear();
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('清空', style: TextStyle(fontSize: 11, color: tg.t3)),
              ),
            ),
    );
  }
}
