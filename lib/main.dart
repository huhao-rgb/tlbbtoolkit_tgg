import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'core/platform/app_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android：edge-to-edge，让 Flutter 内容绘制到系统栏背后，
  // 配合顶栏毛玻璃实现沉浸式状态栏/导航栏（iOS / Web / 桌面本身即全屏绘制）。
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // 桌面端（macOS/Windows/Linux）：frameless 窗口 + 自定义标题栏初始化。
  await initDesktopWindow();

  // 在 runApp 前获取 SharedPreferences，避免首帧异步竞态。
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // 注入全局 SharedPreferences 实例。
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TlbbApp(),
    ),
  );
}
