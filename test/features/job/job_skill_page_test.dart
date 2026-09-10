import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_skill_page.dart';

/// 以完整主题（含 TgColors extension）泵入职业技能库页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1200, 1000),
  String? initialSect,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: Scaffold(
        body: JobSkillPage(initialSect: initialSect),
      ),
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

    // 心法 chips：全部 + 7 本心法（官网数据）
    expect(find.text('全部'), findsOneWidget);
    for (final name in [
      '百花经',
      '遁甲天书',
      '太平要术',
      '短歌行',
      '丹青引',
      '惊涛掌法',
      '北冥神功',
    ]) {
      expect(find.text(name), findsWidgets);
    }

    // xf-note（全部）
    expect(find.textContaining('七本心法 · 共 24 门绝技'), findsOneWidget);

    // 表头
    expect(find.text('技能'), findsWidgets);
    expect(find.text('类型'), findsWidgets);
    expect(find.text('冷却'), findsWidgets);
    expect(find.text('描述'), findsWidgets);

    // 逍遥第一本心法技能行
    expect(find.text('百花经'), findsNWidgets(2)); // chip + 分组头
    expect(find.text('落英剑'), findsWidgets);
    // 技能图标（`.sk-ic`：30×30 图片已渲染）
    expect(find.byType(Image), findsWidgets);
    expect(find.text('攻击'), findsWidgets);
    expect(find.text('—'), findsWidgets);
    expect(find.textContaining('逍遥弟子的入门功夫'), findsOneWidget);
  });

  testWidgets('点心法 chip 单独查看该心法技能', (tester) async {
    await pumpPage(tester);

    // 点击「百花经」心法 chip（第一个出现）
    await tester.tap(find.text('百花经').first);
    await tester.pumpAndSettle();

    // note 切换为心法说明，不再有分组头「…门」
    expect(find.textContaining('「百花经」 · 据说传自盛唐'), findsOneWidget);
    expect(find.textContaining('门绝技'), findsNothing);
    // 只剩第一本心法技能（落英剑 / 桃花阵 / 墨守成规）
    expect(find.text('落英剑'), findsOneWidget);
    expect(find.text('桃花阵'), findsOneWidget);
    expect(find.text('墨守成规'), findsOneWidget);
    expect(find.text('弹指神功'), findsNothing);

    // 切回全部
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(find.textContaining('七本心法 · 共 24 门绝技'), findsOneWidget);
  });

  testWidgets('切换门派：天龙后门派名 / 心法 / 技能更新', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('天龙'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('天龙'));
    await tester.pumpAndSettle();

    expect(find.text('天龙'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内外 · 兼修'), findsOneWidget);
    expect(find.textContaining('七本心法 · 共 24 门绝技'), findsOneWidget);
    // 天龙心法首本：一阳指指法
    expect(find.text('一阳指指法'), findsWidgets);
    expect(find.text('正阳手'), findsWidgets);
    expect(find.text('百花经'), findsNothing);
  });

  testWidgets('切换门派：曼陀山庄官网完整技能且不崩溃', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('曼陀山庄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('曼陀山庄'));
    await tester.pumpAndSettle();

    expect(find.text('曼陀山庄'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内功 · 琴音'), findsOneWidget);
    expect(find.textContaining('七本心法 · 共 13 门绝技'), findsOneWidget);
    // 官网心法 chips（玄音曲 / 流芳诀 …）与技能
    expect(find.text('玄音曲'), findsWidgets);
    expect(find.text('余音袅袅'), findsWidgets);
    expect(find.text('列子御风'), findsWidgets);
    expect(find.text('心无旁骛'), findsWidgets);
  });

  testWidgets('initialSect 跨页定位：传入天龙 → 默认即天龙门派', (tester) async {
    await pumpPage(tester, initialSect: 'tianlong');

    // 默认选中天龙（非逍遥），显示天龙心法首本
    expect(find.text('天龙'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内外 · 兼修'), findsOneWidget);
    expect(find.text('一阳指指法'), findsWidgets);
    expect(find.text('正阳手'), findsWidgets);
    expect(find.text('百花经'), findsNothing);
  });

  testWidgets('initialSect 非法值回退默认逍遥', (tester) async {
    await pumpPage(tester, initialSect: 'not-a-sect');

    expect(find.text('逍遥'), findsNWidgets(2));
    expect(find.text('内功 · 控制'), findsOneWidget);
  });
}
