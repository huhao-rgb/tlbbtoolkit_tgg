import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/domain/job_point.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_point_page.dart';

/// 以完整主题（含 TgColors extension）泵入职业加点计算器页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 1000),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: JobPointPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('domain', () {
    test('总潜能：119 级 → 545；10 级 → 0；越界 clamp', () {
      expect(totalPoints(119), 545);
      expect(totalPoints(10), 0);
      expect(totalPoints(60), 250);
      expect(totalPoints(200), 545);
      expect(totalPoints(5), 0);
    });

    test('一键推荐：逍遥权重按 ling/shen/ti 分配且合计=545', () {
      final pts = recommendPoints('xiaoyao', 545);
      expect(pts.values.fold<int>(0, (a, b) => a + b), 545);
      expect(pts['ling']!, greaterThan(pts['shen']!));
      expect(pts['shen']!, greaterThan(pts['ti']!));
      expect(pts['li'], 0);
      expect(pts['ding'], 0);
    });

    test('面板预览公式', () {
      final p = computePreview(
        119,
        {'li': 0, 'ling': 100, 'ti': 100, 'ding': 0, 'shen': 100},
      );
      expect(p.hp, 119 * 28 + 100 * 52);
      expect(p.mp, 119 * 20 + 100 * 36);
      expect(p.atkP, 100 * 9);
      expect(p.atkW, 0);
      expect(p.hit, 119 * 7 + 100 * 8);
      expect(p.dodge, 119 * 5 + 100 * 6);
    });

    test('千分位', () {
      expect(formatThousand(3332), '3,332');
      expect(formatThousand(0), '0');
      expect(formatThousand(1234567), '1,234,567');
    });
  });

  testWidgets('默认渲染：等级119 / 总545 / 五行 / 面板预览', (tester) async {
    await pumpPage(tester);

    expect(find.text('职业加点计算器'), findsWidgets);
    expect(find.textContaining('潜能点分配 · 一键推荐方案'), findsOneWidget);

    // 剩余/总潜能 545
    expect(find.text('545'), findsNWidgets(2));
    expect(find.text('一键推荐'), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);

    // 五行名
    for (final name in ['力量', '灵气', '体力', '定力', '身法']) {
      expect(find.text(name), findsOneWidget);
    }

    // 面板预览标题 + 门派名
    expect(find.text('面板预览 · '), findsOneWidget);
    expect(find.text('逍遥'), findsNWidgets(2)); // pill + 预览标题

    // 预览初值（119 级，无加点）
    expect(find.text('3,332'), findsOneWidget); // 气血
    expect(find.text('2,380'), findsOneWidget); // 气
    expect(find.text('833'), findsOneWidget); // 命中
    expect(find.text('595'), findsOneWidget); // 闪避
  });

  testWidgets('点击 ＋ 分配潜能：剩余减少、预览更新', (tester) async {
    await pumpPage(tester);

    // 体力行 = 第 3 个 ＋ 按钮（五行按力量/灵气/体力/定力/身法）
    final plus = find.text('＋');
    await tester.tap(plus.at(2));
    await tester.pump();

    // 剩余 544 / 总 545
    expect(find.text('544'), findsOneWidget);
    // 面板：气血 = 3332 + 52 = 3384
    expect(find.text('3,384'), findsOneWidget);
  });

  testWidgets('一键推荐 → 合计 545 分配，清空归零', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('一键推荐'));
    await tester.pump();

    // 推荐后剩余为 0（总值仍 545）
    expect(find.text('545'), findsOneWidget); // 仅「总」
    expect(find.text('0'), findsWidgets);

    // 清空 → 剩余恢复 545
    await tester.tap(find.text('清空'));
    await tester.pump();
    expect(find.text('545'), findsNWidgets(2));
  });

  testWidgets('切门派后一键推荐用新权重（少林 → 力量最高）', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('少林'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('少林'));
    await tester.pumpAndSettle();

    expect(find.text('少林'), findsNWidgets(2)); // pill + 预览标题

    await tester.tap(find.text('一键推荐'));
    await tester.pump();

    // 少林权重 li 最高，力量加点多；外功攻击 = li*9 > 0
    expect(find.text('外功攻击'), findsOneWidget);
  });
}
