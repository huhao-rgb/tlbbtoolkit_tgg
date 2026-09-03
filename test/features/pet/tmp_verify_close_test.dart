import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_suit_page.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';

Future<void> pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1180, 900) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: PetSuitPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('关闭按钮：X 渲染 14x14，点击可关闭弹窗', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('勇猛套装'));
    await tester.pumpAndSettle();

    // 弹窗出现
    expect(find.text('五件套部件'), findsOneWidget);

    // 关闭按钮（Ink 30x30）
    final inkFinder = find.byWidgetPredicate((w) => w is Ink && w.width == 30 && w.height == 30);
    expect(inkFinder, findsOneWidget);

    // X 图标渲染尺寸应为 14x14（不再是 28x28）
    final svg = find.descendant(of: inkFinder, matching: find.byType(SvgPicture));
    final svgBox = tester.renderObject<RenderBox>(svg);
    expect(svgBox.size, const Size(14, 14), reason: 'X 图标应渲染为 14x14，与原型一致');

    // 点击关闭按钮
    await tester.tap(inkFinder);
    await tester.pumpAndSettle();
    expect(find.text('五件套部件'), findsNothing);
  });
}
