import 'package:flutter/foundation.dart';

import 'desktop_window.dart'
    if (dart.library.html) 'desktop_window_stub.dart'
    as impl;

/// ── 平台判定（不依赖 window_manager，可安全在任意平台引用） ──────────────

/// 是否为原生桌面窗口（macOS / Windows / Linux，非 Web / 非移动端）。
bool get isDesktopWindow {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };
}

/// macOS 是否保留系统红绿灯（最小化 / 缩放 / 关闭在左上角）。
bool get macTrafficLights =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Windows / Linux：系统无按钮，标题栏右侧绘制自定义 最小化/最大化/关闭。
bool get showCustomWindowButtons => isDesktopWindow && !macTrafficLights;

/// 标题栏左侧留位：macOS 给红绿灯 ~78px；其余按原型 `padding-left:14px`。
double get titleBarLeadingPadding => macTrafficLights ? 78 : 14;

/// ── 最大化状态订阅（标题栏「最大化 ↔ 还原」图标） ──────────────────────

final Set<void Function(bool)> _maximizeListeners = {};

void subscribeMaximize(void Function(bool) onChanged) {
  _maximizeListeners.add(onChanged);
  if (_maximizeListeners.length == 1) {
    impl.attachMaximizeListener(_notifyMaximize);
  }
}

void unsubscribeMaximize(void Function(bool) onChanged) {
  _maximizeListeners.remove(onChanged);
  if (_maximizeListeners.isEmpty) {
    impl.detachMaximizeListener();
  }
}

void _notifyMaximize(bool maximized) {
  for (final cb in List.of(_maximizeListeners)) {
    cb(maximized);
  }
}

/// ── 窗口操作代理 ─────────────────────────────────────────────────────────

Future<void> initDesktopWindow() => impl.initDesktopWindow();

Future<void> windowMinimize() => impl.minimize();

Future<void> windowMaximizeToggle() => impl.toggleMaximize();

Future<void> windowClose() => impl.close();

Future<void> windowStartDragging() => impl.startDragging();

Future<bool> windowIsMaximized() => impl.isMaximized();
