import 'package:flutter/material.dart';

/// 页面入场动画（对应原型 `@keyframes fadein`：opacity 0→1 · translateY 8px→0 · .28s ease）。
///
/// 页面实例首次 build 时播放一次；同一页面内的 setState 重建不会重复播放
/// （如首页筛选/搜索）。将其包在页面内容最外层即可。
class TgPageEntrance extends StatefulWidget {
  const TgPageEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<TgPageEntrance> createState() => _TgPageEntranceState();
}

class _TgPageEntranceState extends State<TgPageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.ease.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
