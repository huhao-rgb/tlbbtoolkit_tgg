import 'package:flutter/material.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/core/responsive/breakpoints.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';

/// 「回到顶部」悬浮按钮（对应原型 `#backTop`，账号 / 珍兽行情两个长页共用）。
///
/// 原型样式：`position:fixed; right:20px; bottom:24px`（移动端 `right:14px;
/// bottom:86px`，即悬浮 tabbar 之上 28px），42×42 圆形，`card` 底 +
/// `border-hi` 1px 描边 + `gold2` 20px 上箭头 + 阴影 `0 10px 26px rgba(0,0,0,.45)`；
/// 滚动 `scrollY > 420` 后才淡入（opacity 0→1 且上移 10px 复原，0.25s），
/// hover 时描边转为金色，点击平滑滚回顶部。
///
/// 用法：与页面**唯一的滚动体**同放一个 [Stack]，并共用同一个
/// [ScrollController]（本组件只做悬浮层与显隐控制，不自建滚动体、不影响
/// 页面布局）：
///
/// ```dart
/// Stack(
///   children: [
///     Positioned.fill(child: CustomScrollView(controller: _scroll, ...)),
///     TgScrollTopButton(controller: _scroll),
///   ],
/// )
/// ```
class TgScrollTopButton extends StatefulWidget {
  const TgScrollTopButton({
    super.key,
    required this.controller,
    this.threshold = 420,
  });

  /// 页面滚动体的控制器；必须与滚动体（如 `CustomScrollView.controller`）
  /// 是同一个实例，本组件据此判断显隐与执行回顶。
  final ScrollController controller;

  /// 滚动超过该距离后才显示（原型 `window.scrollY > 420`）。
  final double threshold;

  /// 稳定 key（测试定位用）。
  static const Key buttonKey = ValueKey('scroll-top-button');

  @override
  State<TgScrollTopButton> createState() => _TgScrollTopButtonState();
}

class _TgScrollTopButtonState extends State<TgScrollTopButton> {
  /// 是否显示（滚动超过阈值）。
  bool _show = false;

  /// hover 态（描边转金色）。
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant TgScrollTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _onScroll();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final c = widget.controller;
    final show = c.hasClients && c.offset > widget.threshold;
    if (show != _show && mounted) setState(() => _show = show);
  }

  /// 平滑滚回顶部（原型 `scrollTo({top:0,behavior:'smooth'})`）。
  void _toTop() {
    final c = widget.controller;
    if (!c.hasClients) return;
    c.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    // 底栏只在移动端布局（< [Breakpoints.desktop]）存在，按钮需让开其高度；
    // 并额外让开系统底部安全区（悬浮 tabbar 自身也含该内缩）。
    final mobile =
        Breakpoints.layoutOf(MediaQuery.sizeOf(context).width) ==
        DeviceLayout.mobile;
    final bottom = mobile
        ? Breakpoints.tabbarOverlayHeight +
              28 +
              MediaQuery.paddingOf(context).bottom
        : 24.0;
    return Positioned(
      right: mobile ? 14 : 20,
      bottom: bottom,
      child: IgnorePointer(
        // 隐藏时不拦截指针（避免挡住页面滚动与点击）。
        ignoring: !_show,
        child: AnimatedOpacity(
          opacity: _show ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            // 原型 translateY(10px) → 相对 42px 高度折算。
            offset: _show ? Offset.zero : const Offset(0, 10 / 42),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Tooltip(
              message: '回到顶部',
              child: MouseRegion(
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  key: TgScrollTopButton.buttonKey,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tg.card,
                    border: Border.all(
                      color: _hover
                          ? tg.gold.withValues(alpha: .5)
                          : tg.borderHi,
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 10),
                        blurRadius: 26,
                        color: Color(0x73000000),
                      ),
                    ],
                  ),
                  child: Material(
                    shape: const CircleBorder(),
                    color: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _toTop,
                      customBorder: const CircleBorder(),
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: tg.gold.withValues(alpha: .12),
                      child: Center(
                        child: TgIcon('up', size: 20, color: tg.gold2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
