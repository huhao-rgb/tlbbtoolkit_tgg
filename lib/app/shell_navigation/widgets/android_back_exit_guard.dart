import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/responsive/breakpoints.dart';

/// Android 系统返回键守卫。
///
/// Android 上「系统返回」在无可返回页面时会**直接关闭应用**，误触成本高。
/// 本组件把该行为改成：
/// 1. 先交给 [onBack] 处理（如 pop 分支导航栈内的详情页）。返回 `true`
///    表示已被消费，不再继续；
/// 2. [onBack] 返回 `false`（确实没有可返回的页面）时，**首次按下只弹提示**
///    「再按一次返回键退出应用」；
/// 3. 在 [exitWindow] 时间窗口内**再次按下**，才真正退出应用
///    （[SystemNavigator.pop]）。超过窗口则重新开始提示，不会误退。
///
/// 非 Android 平台（iOS / Web / 桌面）原样返回 [child]：既不接管返回键，
/// 也避免 `PopScope(canPop: false)` 关掉 iOS 的侧滑返回手势。
class AndroidBackExitGuard extends StatefulWidget {
  const AndroidBackExitGuard({
    super.key,
    required this.onBack,
    required this.child,
  });

  /// 处理一次系统返回请求。
  ///
  /// 返回 `true` 表示已消费（如已 pop 上一页）；`false` 表示当前已无可返回
  /// 的页面，交由守卫走「再按一次退出」流程。
  final bool Function() onBack;

  /// 被守卫的内容。
  final Widget child;

  /// 「再按一次退出」的有效时间窗口；两次按下间隔超过它则重新提示。
  static const Duration exitWindow = Duration(seconds: 2);

  /// 退出提示文案。
  static const String exitHint = '再按一次返回键退出应用';

  @override
  State<AndroidBackExitGuard> createState() => _AndroidBackExitGuardState();
}

class _AndroidBackExitGuardState extends State<AndroidBackExitGuard> {
  /// 上一次「无可返回页面」时按下返回键的时刻，用于判定是否在窗口内。
  DateTime? _lastPressedAt;

  /// 顶部提示是否可见（[AndroidBackExitGuard.exitWindow] 后自动收起）。
  bool _hintVisible = false;

  /// 提示自动收起计时器。
  Timer? _hintTimer;

  /// 仅在 Android 原生（非 Web）上接管返回键。
  bool get _enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;

    // 能返回上一层：正常返回，并重置窗口，避免残留时间戳影响后续判定。
    if (widget.onBack()) {
      _lastPressedAt = null;
      return;
    }

    final now = DateTime.now();
    final last = _lastPressedAt;
    if (last != null &&
        now.difference(last) <= AndroidBackExitGuard.exitWindow) {
      // 窗口内再次按下 → 退出应用。
      _hintTimer?.cancel();
      SystemNavigator.pop();
      return;
    }

    _lastPressedAt = now;
    _showExitHint();
  }

  /// 在**页面顶部**弹「再按一次返回键退出应用」提示。
  ///
  /// 自绘顶部浮层而非 SnackBar：SnackBar 只能贴底部，会被悬浮毛玻璃 tabbar
  /// 压住；顶部单独成条 + 1px 金边更醒目（暗色背景下尤其）。显示时长
  /// = [AndroidBackExitGuard.exitWindow]，与「再按一次」的判定窗口一致。
  void _showExitHint() {
    _hintTimer?.cancel();
    if (!_hintVisible) setState(() => _hintVisible = true);
    _hintTimer = Timer(AndroidBackExitGuard.exitWindow, () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;
    return PopScope(
      // 完全接管：所有系统返回都先经 [_onPopInvokedWithResult] ——
      // 可返回时由 `onBack` 自行 pop，不可返回时走「再按一次退出」。
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          // 顶部提示层：紧贴悬浮信息条下方（安全区 + 信息条高度），纯视觉、
          // 不拦截页面交互。
          Positioned(
            top:
                MediaQuery.paddingOf(context).top +
                Breakpoints.topbarOverlayHeight +
                8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _hintVisible
                    ? const _ExitHint()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部退出提示条：居中卡片，1px 金边 + 阴影（暗色背景下与页面拉开层次），
/// 文案固定为 [AndroidBackExitGuard.exitHint]。
class _ExitHint extends StatelessWidget {
  const _ExitHint();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final isDark = tg.brightness == Brightness.dark;

    // 本浮层是 shell（Scaffold）的**兄弟节点**，拿不到 Material 提供的
    // DefaultTextStyle，文字会继承 WidgetsApp 的兜底错误样式 —— 字号会被下方
    // style 覆盖，但会残留“黄色双下划线”。故外层补透明 Material，文字显式
    // decoration:none（同 `window_title_bar.dart` 的处理）。
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: tg.card2,
            borderRadius: TgRadius.card,
            // 金色描边：与主题一致，且比纯卡片底（card2）在暗色下更醒目。
            border: Border.all(color: tg.gold.withValues(alpha: .55), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .45 : .16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            AndroidBackExitGuard.exitHint,
            textAlign: TextAlign.center,
            style: TgType.row13.copyWith(
              color: tg.t1,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
