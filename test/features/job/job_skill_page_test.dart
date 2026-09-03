import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_skill_page.dart';

/// 以完整主题（含 TgColors extension）泵入职业技能库页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1200, 1000),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: JobSkillPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 门派 + 心法 chips + 逍遥全部分组', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('职业技能库'), findsWidgets);
    expect(find.textContaining('按门派查看技能类型'), findsOneWidget);

    // 门派 pill（逍遥也作当前门派名）
    expect(find.text('逍遥'), findsNWidgets(2));
    expect(find.text('内功 · 控制'), findsOneWidget);

    // 心法 chips：全部 + 7 本心法
    expect(find.text('全部'), findsOneWidget);
    for (final name in [
      '北冥神功',
      '小无相功',
      '凌波微步',
      '八荒六合功',
      '逍遥御风',
      '传音搜魂',
      '五行奇门',
    ]) {
      expect(find.text(name), findsWidgets);
    }

    // xf-note（全部）
    expect(find.textContaining('七本心法 · 共 12 门绝技'), findsOneWidget);

    // 表头
    expect(find.text('技能'), findsWidgets);
    expect(find.text('类型'), findsWidgets);
    expect(find.text('冷却'), findsWidgets);
    expect(find.text('描述'), findsWidgets);

    // 逍遥第一本心法技能行
    expect(find.text('北冥神功'), findsNWidgets(3)); // chip + 分组头 + 技能行
    expect(find.text('主动'), findsWidgets);
    expect(find.text('30s'), findsWidgets);
    expect(find.textContaining('吸取目标内力并造成内功伤害'), findsOneWidget);
  });

  testWidgets('点心法 chip 单独查看该心法技能', (tester) async {
    await pumpPage(tester);

    // 点击「北冥神功」心法 chip（第一个出现）
    await tester.tap(find.text('北冥神功').first);
    await tester.pumpAndSettle();

    // note 切换为心法说明，不再有分组头「…门」
    expect(find.textContaining('「北冥神功」 · 吸纳内力，化为己用'), findsOneWidget);
    expect(find.textContaining('门绝技'), findsNothing);
    // 只剩 1 条技能行（北冥神功 主动）
    expect(find.text('北冥神功'), findsNWidgets(2)); // chip + 技能行
    expect(find.text('溪山行旅'), findsNothing);

    // 切回全部
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(find.textContaining('七本心法 · 共 12 门绝技'), findsOneWidget);
  });

  testWidgets('切换门派：天山后门派名 / 心法 / 技能更新', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('天山'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('天山'));
    await tester.pumpAndSettle();

    expect(find.text('天山'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('外功 · 刺客'), findsOneWidget);
    expect(find.textContaining('七本心法 · 共 12 门绝技'), findsOneWidget);
    // 天山心法首本：天山折梅手
    expect(find.text('天山折梅手'), findsWidgets);
    expect(find.text('北冥神功'), findsNothing);
  });
}
