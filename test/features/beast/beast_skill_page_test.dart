import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/beast/presentation/pages/beast_skill_page.dart';

/// 以完整主题（含 TgColors extension）泵入兽灵技能效果页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 900),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: BeastSkillPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 5 技能手风琴，第一项展开', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('兽灵技能效果'), findsOneWidget);
    expect(find.textContaining('点击展开 Lv.1-5 等级数值表'), findsOneWidget);

    // 5 个技能名 + 类别 tag（均在标题行，无论展开与否都在树中）
    for (final name in ['破军', '天罚', '嗜血', '护主', '威慑']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('主动'), findsNWidgets(2)); // 破军 · 天罚
    expect(find.text('被动'), findsNWidgets(2)); // 嗜血 · 护主
    expect(find.text('控制'), findsOneWidget); // 威慑

    // 默认展开第一项（破军）：Lv.1-5 与效果行可见
    for (final lv in ['Lv.1', 'Lv.2', 'Lv.3', 'Lv.4', 'Lv.5']) {
      expect(find.text(lv), findsOneWidget);
    }
    expect(find.text('造成 180% 伤害'), findsOneWidget);
    expect(find.text('冷却 40s'), findsNWidgets(2)); // Lv.1 / Lv.2 均为 40s

    // 其余技能仍折叠：天罚的行不在树中
    expect(find.text('140% 范围伤害'), findsNothing);
    expect(find.text('吸血 8%'), findsNothing);
  });

  testWidgets('点击标题展开/收起对应等级表，可多开', (tester) async {
    await pumpPage(tester);

    // 展开天罚（第二项）
    await tester.ensureVisible(find.text('天罚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('天罚'));
    await tester.pumpAndSettle();

    // 破军仍展开 + 天罚展开 → Lv.1 出现两处
    expect(find.text('Lv.1'), findsNWidgets(2));
    expect(find.text('140% 范围伤害'), findsOneWidget);
    expect(find.text('冷却 50s'), findsOneWidget);

    // 再展开嗜血（被动）：吸血 8% 出现
    await tester.ensureVisible(find.text('嗜血'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('嗜血'));
    await tester.pumpAndSettle();
    expect(find.text('吸血 8%'), findsOneWidget);
    expect(find.text('Lv.1'), findsNWidgets(3));

    // 收起天罚：其行消失、破军/嗜血仍在
    await tester.ensureVisible(find.text('天罚'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('天罚'));
    await tester.pumpAndSettle();
    expect(find.text('140% 范围伤害'), findsNothing);
    expect(find.text('造成 180% 伤害'), findsOneWidget);
    expect(find.text('吸血 8%'), findsOneWidget);
    expect(find.text('Lv.1'), findsNWidgets(2));
  });

  testWidgets('页脚展示', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(
      find.text('天工阁 · 玩家自制工具集合，与畅游官方无关'),
    );
    await tester.pumpAndSettle();
    expect(find.text('天工阁 · 玩家自制工具集合，与畅游官方无关'), findsOneWidget);
  });
}
