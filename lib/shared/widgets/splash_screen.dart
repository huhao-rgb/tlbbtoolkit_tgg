import 'dart:async';

import 'package:flutter/material.dart';

/// 天工阁全幅启动图（Flutter 层冷启动闪屏）。
///
/// 背景：Android 12+ 原生系统启动屏只能显示「图标 + 背景色」，无法展示
/// 整幅 splash 图；iOS 原生 LaunchScreen 可以全幅。为了让两端（尤其是
/// Android 12+）在冷启动时都能看到完整的天工阁启动图，这里在 Flutter
/// 首帧之上叠加一帧全幅启动图，约 [duration] 后淡出露出主界面。
class AppSplashGate extends StatefulWidget {
  const AppSplashGate({super.key, required this.child});

  /// 底层的应用内容（MaterialApp 等）。
  final Widget child;

  /// 启动图展示时长（之后开始淡出）。
  static const Duration duration = Duration(milliseconds: 1300);

  /// 淡出时长。
  static const Duration fadeDuration = Duration(milliseconds: 480);

  @override
  State<AppSplashGate> createState() => _AppSplashGateState();
}

class _AppSplashGateState extends State<AppSplashGate> {
  bool _show = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppSplashGate.duration, () {
      if (mounted) setState(() => _show = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppSplashGate 位于 MaterialApp 之外，Stack 的默认对齐
    // (AlignmentDirectional.topStart) 需要 Directionality 祖先，
    // 这里手动提供，避免冷启动报 "No Directionality widget"。
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          // 启动图覆盖层：展示期间拦截事件，淡出后不参与命中
          IgnorePointer(
            ignoring: !_show,
            child: AnimatedOpacity(
              opacity: _show ? 1 : 0,
              duration: AppSplashGate.fadeDuration,
              curve: Curves.easeOut,
              child: const _SplashArt(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 全幅启动图（等比覆盖裁切；四周深色，裁切不可见）。
class _SplashArt extends StatelessWidget {
  const _SplashArt();

  /// 与 splash.png 四边一致的底色，避免异形屏/横屏出现黑边。
  static const Color _bg = Color(0xFF0A0805);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Image.asset(
        'assets/splash/splash.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
