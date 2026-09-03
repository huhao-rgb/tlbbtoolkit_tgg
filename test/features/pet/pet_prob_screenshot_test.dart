import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_prob_page.dart';

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String p) async =>
      ByteData.sublistView(await File(p).readAsBytes());
  final regular = FontLoader('Noto Sans SC')..addFont(bytes('/Users/hu/Documents/tlbbtoolkit/assets/fonts/NotoSansSC-Regular.ttf'));
  await regular.load();
  final medium = FontLoader('Noto Sans SC')..addFont(bytes('/Users/hu/Documents/tlbbtoolkit/assets/fonts/NotoSansSC-Medium.ttf'));
  await medium.load();
  final serifM = FontLoader('Noto Serif SC')..addFont(bytes('/Users/hu/Documents/tlbbtoolkit/assets/fonts/NotoSerifSC-Medium.ttf'));
  await serifM.load();
  final serifSB = FontLoader('Noto Serif SC')..addFont(bytes('/Users/hu/Documents/tlbbtoolkit/assets/fonts/NotoSerifSC-SemiBold.ttf'));
  await serifSB.load();
}

Future<void> _snap(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  testWidgets('capture screenshots', (tester) async {
    await tester.runAsync(_loadFonts);

    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1180, 860) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TgTheme.dark,
          darkTheme: TgTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: PetProbPage()),
        ),
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      await _snap(tester, '/Users/hu/Documents/tlbbtoolkit/build/pet_prob_wide.png');
    });

    // 窄屏
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      await tester.pump(const Duration(milliseconds: 400));
      await _snap(tester, '/Users/hu/Documents/tlbbtoolkit/build/pet_prob_narrow.png');
    });
  });
}
