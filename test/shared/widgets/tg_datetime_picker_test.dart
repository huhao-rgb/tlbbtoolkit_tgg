import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_datetime_picker.dart';

/// 面包屑当前页的文字色（金 = 当前页）。
Color crumbColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

/// 把字段放进 1200×1000 的画布，避免面板被 600 高的默认测试窗口裁掉。
Future<void> pumpField(
  WidgetTester tester, {
  required DateTime value,
  required TgDateTimeDirection direction,
  required ValueChanged<DateTime> onChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: TgDateTimeField(
              value: value,
              direction: direction,
              timeCaption: '上线时刻',
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('点字段弹出面板，选日期后自动滑入时间页，确定回填', (tester) async {
    final now = DateTime.now();
    DateTime? result;
    await pumpField(
      tester,
      value: now,
      direction: TgDateTimeDirection.past,
      onChanged: (v) => result = v,
    );

    await tester.tap(find.byType(TgDateTimeField));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tg-dtp-panel')), findsOneWidget);
    expect(find.text('① 选择日期'), findsOneWidget);

    final dayKey = ValueKey('tg-dtp-day-${now.year}-${now.month}-${now.day}');
    await tester.tap(find.byKey(dayKey));
    // 0.22s 后自动切到时间页。
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(crumbColor(tester, '② 选择时间'), TgColors.dark.gold);
    expect(find.text('上线时刻'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tg-dtp-ok')));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.year, now.year);
    expect(result!.month, now.month);
    expect(result!.day, now.day);
    expect(find.byKey(const Key('tg-dtp-panel')), findsNothing);
  });

  testWidgets('past 方向禁用未来日期', (tester) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    DateTime? result;
    await pumpField(
      tester,
      value: now,
      direction: TgDateTimeDirection.past,
      onChanged: (v) => result = v,
    );

    await tester.tap(find.byType(TgDateTimeField));
    await tester.pumpAndSettle();

    final key = ValueKey(
      'tg-dtp-day-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}',
    );
    await tester.tap(find.byKey(key));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 仍在日期页（未自动进入时间页），也未回填。
    expect(crumbColor(tester, '① 选择日期'), TgColors.dark.gold);
    expect(result, isNull);
  });

  testWidgets('future 方向的快捷时刻整组回填并关闭面板', (tester) async {
    final now = DateTime.now();
    DateTime? result;
    await pumpField(
      tester,
      value: now,
      direction: TgDateTimeDirection.future,
      onChanged: (v) => result = v,
    );

    await tester.tap(find.byType(TgDateTimeField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('明天 09:00'));
    await tester.pumpAndSettle();

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    expect(result, isNotNull);
    expect(result!.year, tomorrow.year);
    expect(result!.month, tomorrow.month);
    expect(result!.day, tomorrow.day);
    expect(result!.hour, 9);
    expect(result!.minute, 0);
    expect(find.byKey(const Key('tg-dtp-panel')), findsNothing);
  });

  testWidgets('点面板外关闭且不回填', (tester) async {
    final now = DateTime.now();
    DateTime? result;
    await pumpField(
      tester,
      value: now,
      direction: TgDateTimeDirection.past,
      onChanged: (v) => result = v,
    );

    await tester.tap(find.byType(TgDateTimeField));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tg-dtp-panel')), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tg-dtp-panel')), findsNothing);
    expect(result, isNull);
  });
}
