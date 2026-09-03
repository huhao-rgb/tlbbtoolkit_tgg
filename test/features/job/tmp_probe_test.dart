import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_point_page.dart';

void main() {
  testWidgets('probe2', (tester) async {
    tester.view.physicalSize = const Size(1200, 600) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TgTheme.dark,
        darkTheme: TgTheme.dark,
        home: const Scaffold(body: JobPointPage()),
      ),
    );
    await tester.pumpAndSettle();

    String c(String label, Rect r) {
      final cy = r.center.dy;
      return '$label rect=$r centerY=$cy';
    }

    // ignore: avoid_print
    print(c('输入框', tester.getRect(find.byType(TextField))));
    // ignore: avoid_print
    print(c('EditableText', tester.getRect(find.byType(EditableText))));
    // ignore: avoid_print
    print(c('等级', tester.getRect(find.text('等级'))));
  });
}
