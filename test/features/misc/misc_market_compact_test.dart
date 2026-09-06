import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/misc/data/pet_market_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/data/pet_market_snapshot.dart';
import 'package:tlbbtoolkit/features/misc/presentation/pages/misc_market_page.dart';

Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: Scaffold(
        body: MiscMarketPage(
          fetchSxds: () async =>
              PetMarketFetchResult(raw: 176, parsed: kPetMarketData),
          fetchRegions: () async => const [],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('紧凑（移动）宽度下渲染无溢出，隐藏区服列', (tester) async {
    await pumpPage(tester);

    // 紧凑布局下不抛 RenderFlex overflow（pump 后无 exception）
    expect(tester.takeException(), isNull);
    expect(find.text('珍兽行情分析'), findsOneWidget);
    expect(find.text('在售样本'), findsOneWidget);

    // 滚动到底部明细表，确认移动端列仍可渲染（无区服列宽溢出）
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('在售明细 · 按价格排序'),
      200,
      scrollable: scrollable,
    );
    expect(tester.takeException(), isNull);

    // 隐藏列：移动端无「区服」表头
    expect(find.text('区服'), findsNothing);
  });
}
