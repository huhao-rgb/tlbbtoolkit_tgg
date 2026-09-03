import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面窗口实现（Windows / macOS / Linux，真实 window_manager）。
///
/// 仅通过 `app_window.dart` 门面按条件引入：Web 端编译期替换为
/// `desktop_window_stub.dart`，移动端因有 dart:io 也编译此文件，
/// 但所有入口都在调用前用 `isDesktopWindow` 守卫，不会触发插件调用。

/// frameless 窗口初始化：隐藏系统标题栏、设定初始尺寸并居中。
Future<void> initDesktopWindow() async {
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1240, 820),
    minimumSize: Size(980, 660),
    center: true,
    title: '天工阁 · 天龙八部怀旧版工具箱',
    // 三平台统一隐藏系统标题栏；macOS 默认保留系统红绿灯
    //（可传 windowButtonVisibility:false 隐藏红绿灯改用自绘按钮）。
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> minimize() async {
  try {
    await windowManager.minimize();
  } catch (_) {}
}

Future<void> toggleMaximize() async {
  try {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  } catch (_) {}
}

Future<void> close() async {
  try {
    await windowManager.close();
  } catch (_) {}
}

Future<void> startDragging() async {
  try {
    await windowManager.startDragging();
  } catch (_) {}
}

Future<bool> isMaximized() async {
  try {
    return await windowManager.isMaximized();
  } catch (_) {
    return false;
  }
}

/// 最大化状态监听（切换按钮图标：最大化 ↔ 还原）。
class _MaximizeListener extends WindowListener {
  _MaximizeListener(this.onChanged);

  final void Function(bool) onChanged;

  @override
  void onWindowMaximize() => onChanged(true);

  @override
  void onWindowUnmaximize() => onChanged(false);

  @override
  void onWindowRestore() => onChanged(false);
}

_MaximizeListener? _listener;

void attachMaximizeListener(void Function(bool) onChanged) {
  if (_listener != null) return;
  _listener = _MaximizeListener(onChanged);
  try {
    windowManager.addListener(_listener!);
  } catch (_) {}
}

void detachMaximizeListener() {
  final l = _listener;
  _listener = null;
  if (l != null) {
    try {
      windowManager.removeListener(l);
    } catch (_) {}
  }
}
