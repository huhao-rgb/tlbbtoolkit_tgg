import 'package:flutter/material.dart';

/// 设计稿（天工阁-Windows安装卸载界面设计稿.html）的视觉变量。
abstract final class T {
  static const pageBg = Color(0xFF0D0D11);
  static const winBg = Color(0xFF15151A);
  static const sideBg = Color(0xFF101014);

  static const gold = Color(0xFFD9B96C);
  static const gold2 = Color(0xFFE8CF96);
  static const deep = Color(0xFFB98A3D);

  static const t1 = Color(0xFFF0EAD9);
  static const t2 = Color(0xFFC9C2AE);

  /// 设计稿为 #8A8578，11px 小字对比度不足，这里提到 AA。
  static const t3 = Color(0xFF9A958A);

  static const danger = Color(0xFFE81123);
  static const ink = Color(0xFF191510);

  static const goldBorder = Color(0x33D9B96C);
  static const hairline = Color(0x14FFFFFF);
  static const hover = Color(0x0DFFFFFF);
  static const card = Color(0xB81A1A20);
  static const field = Color(0x40000000);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold2, deep],
  );

  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD96C6C), Color(0xFFB93D3D)],
  );

  static const titleBarHeight = 46.0;
  static const sideWidth = 284.0;
  static const footerHeight = 66.0;
  static const windowSize = Size(960, 672);
  static const minWindowSize = Size(880, 600);

  static const sansFamily = 'NotoSansSC';
  static const sansFallback = ['Segoe UI', 'Microsoft YaHei', 'PingFang SC'];

  static const serifFamily = 'KaiTi';
  static const serifFallback = [
    'NotoSansSC',
    'STKaiti',
    'Kaiti SC',
    'NotoSerifSC',
    'Songti SC',
  ];

  static TextStyle sans({
    double size = 13,
    Color color = t1,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sansFallback,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle serif({
    double size = 15,
    Color color = gold2,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 3,
  }) => TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}
