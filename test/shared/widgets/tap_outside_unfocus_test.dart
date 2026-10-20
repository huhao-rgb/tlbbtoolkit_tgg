import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/shared/widgets/tap_outside_unfocus.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_text_field.dart';

void main() {
  /// 单个输入框是否持有焦点（[EditableText] 内部持有实际焦点）。
  bool focused(WidgetTester tester, [Finder? scope]) {
    final finder = scope == null
        ? find.byType(EditableText)
        : find.descendant(of: scope, matching: find.byType(EditableText));
    return tester.state<EditableTextState>(finder).widget.focusNode.hasFocus;
  }

  /// 与 App 根部一致：把页面包在 [TapOutsideUnfocus] 里，下方留出空白区。
  Widget host({Widget? field}) {
    return MaterialApp(
      theme: TgTheme.dark,
      home: TapOutsideUnfocus(
        child: Scaffold(
          body: Column(
            children: [
              field ?? const TextField(),
              const SizedBox(height: 240),
              const Text('空白区'),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('点击输入框以外的区域：失焦', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(focused(tester), isTrue);

    await tester.tap(find.text('空白区'));
    await tester.pumpAndSettle();
    expect(focused(tester), isFalse);
  });

  testWidgets('从输入框外拖动（滑动列表）：不失焦', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(focused(tester), isTrue);

    // 按下与抬手相距很远 → 判定为拖动，保持焦点以便继续输入。
    await tester.drag(find.text('空白区'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(focused(tester), isTrue);
  });

  testWidgets('TgTextField：点后缀按钮（清空）不算点外部，保持焦点', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      host(
        field: TgTextField(
          hintText: '搜索',
          suffix: GestureDetector(
            key: const Key('suffix'),
            behavior: HitTestBehavior.opaque,
            onTap: () => tapped++,
            child: const SizedBox(width: 40, height: 24),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(focused(tester), isTrue);

    await tester.tap(find.byKey(const Key('suffix')));
    await tester.pumpAndSettle();
    expect(tapped, 1);
    expect(focused(tester), isTrue);
  });

  testWidgets('点另一个输入框：焦点由新输入框接管', (tester) async {
    const firstKey = Key('first');
    const secondKey = Key('second');
    await tester.pumpWidget(
      MaterialApp(
        theme: TgTheme.dark,
        home: TapOutsideUnfocus(
          child: const Scaffold(
            body: Column(
              children: [
                TextField(key: firstKey),
                TextField(key: secondKey),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(firstKey));
    await tester.pumpAndSettle();
    expect(focused(tester, find.byKey(firstKey)), isTrue);

    await tester.tap(find.byKey(secondKey));
    await tester.pumpAndSettle();
    expect(focused(tester, find.byKey(firstKey)), isFalse);
    expect(focused(tester, find.byKey(secondKey)), isTrue);
  });
}
