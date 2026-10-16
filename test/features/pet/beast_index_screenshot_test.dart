import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/beast_index_page.dart';

/// 兽灵图鉴整页快照（桌面 / 移动端、收起 / 展开 / 待补四种状态）。
///
/// 产物写入 `build/beast_index_*.png`，用于对照原型 v1.13.0 目视核对。
Future<void> _loadFonts() async {
  Future<ByteData> bytes(String p) async =>
      ByteData.sublistView(await File(p).readAsBytes());
  for (final entry in {
    'Noto Sans SC': ['NotoSansSC-Regular.ttf', 'NotoSansSC-Medium.ttf'],
    'Noto Serif SC': ['NotoSerifSC-Medium.ttf', 'NotoSerifSC-SemiBold.ttf'],
  }.entries) {
    for (final f in entry.value) {
      final loader = FontLoader(entry.key)
        ..addFont(bytes('/Users/hu/Documents/tlbbtoolkit/assets/fonts/$f'));
      await loader.load();
    }
  }
}

Future<void> _snap(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('/Users/hu/Documents/tlbbtoolkit/build/beast_index_$name.png')
      .writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  testWidgets('capture screenshots', (tester) async {
    await tester.runAsync(_loadFonts);

    // 每张快照用独立 key：pumpWidget 会复用同位置的 State，
    // 不复位会带着上一张的手风琴展开态。
    var seq = 0;
    Future<void> pumpAt(double w, double h) async {
      seq++;
      tester.view.physicalSize = Size(w, h) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TgTheme.dark,
          darkTheme: TgTheme.dark,
          themeMode: ThemeMode.dark,
          home: Scaffold(body: BeastIndexPage(key: ValueKey('shot-$seq'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 桌面 · 初始态（首项破御默认展开）
    await pumpAt(1180, 1000);
    await tester.runAsync(() => _snap(tester, 'desktop'));

    // 桌面 · 破御切到四阶
    await pumpAt(1180, 1500);
    await tester.tap(find.text('四阶 · 10-12 级'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => _snap(tester, 'expanded'));

    // 桌面 · 展开拼命（待补态）
    await pumpAt(1180, 1100);
    await tester.tap(find.text('拼命兽灵'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => _snap(tester, 'pending'));

    // 移动端 · 破御切到七阶
    await pumpAt(390, 1500);
    await tester.tap(find.text('七阶 · 20 级'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => _snap(tester, 'mobile'));
  });
}
