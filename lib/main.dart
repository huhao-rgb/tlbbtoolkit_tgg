import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'core/platform/app_window.dart';
import 'shared/widgets/splash_screen.dart';

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

  // iOS：原生 LaunchScreen 会展示全幅启动图但时长很短，叠加 Flutter 全幅
  // 启动页把它拉长到 1.3s 再淡出进首页；桌面 / Web 不叠加。
  // Android：整幅启动图已由原生 SplashActivity（windowBackground）渲染，
  // Flutter 侧不再叠加，避免重复显示。
  final needsSplashGate =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  final app = ProviderScope(
    overrides: [
      // 注入全局 SharedPreferences 实例。
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const TlbbApp(),
  );

  runApp(needsSplashGate ? AppSplashGate(child: app) : app);
}
