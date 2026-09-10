import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_wudao_page.dart';

/// 以完整主题（含 TgColors extension）泵入职业武道页。
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
      home: const Scaffold(body: JobWudaoPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 12 门派 + 逍遥两流派卡（官网数据）', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('职业武道'), findsWidgets); // 顶栏标题 + h1
    expect(find.textContaining('选择门派，查看攻伐与御守'), findsOneWidget);

    // 12 门派 pill（逍遥还作为当前门派名出现一次）
    for (final name in ['少林', '明教', '丐帮', '天山', '峨眉', '武当', '星宿', '慕容', '曼陀山庄', '天龙', '恶人谷']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('逍遥'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内功 · 控制'), findsOneWidget);

    // 逍遥两个流派卡（官网数据）
    expect(find.text('飘逸输出'), findsOneWidget);
    expect(find.text('陷阱大师'), findsOneWidget);
    expect(find.textContaining('流派 1 / 2'), findsOneWidget);
    expect(find.textContaining('流派 2 / 2'), findsOneWidget);

    // 流派被动
    expect(find.textContaining('流派被动 · 飞星晔夜'), findsOneWidget);
    expect(find.textContaining('流派被动 · 欺烟困雨'), findsOneWidget);

    // 第一流派节点（武道一重起）
    expect(find.text('落英剑·神威'), findsWidgets);
    expect(find.text('霁月行空'), findsWidgets);
    // 层标题 + 同层择一提示
    expect(find.text('武道一重'), findsNWidgets(2));
    expect(find.text('同层择一 · 每个武道 5 级'), findsWidgets);
  });

  testWidgets('切换门派：点武当后门派名与定位更新 + 官网流派', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('武当'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('武当'));
    await tester.pumpAndSettle();

    expect(find.text('武当'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内功 · 均衡'), findsOneWidget);
    // 武当官网流派
    expect(find.text('单体输出'), findsOneWidget);
    expect(find.text('移动输出'), findsOneWidget);
    expect(find.textContaining('流派被动 · 海纳川行诀'), findsOneWidget);
  });

  testWidgets('切换门派：恶人谷 3 层每层 10 节点（官网数据）', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('恶人谷'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恶人谷'));
    await tester.pumpAndSettle();

    expect(find.text('恶人谷'), findsNWidgets(2));
    expect(find.text('内功 · 刺客'), findsOneWidget);
    expect(find.text('溯魂'), findsOneWidget);
    expect(find.text('判命'), findsOneWidget);
    expect(find.text('剜心镰·神威'), findsWidgets);
    // 3 层（恶人谷无第四重）
    expect(find.text('武道一重'), findsWidgets);
    expect(find.text('武道三重'), findsWidgets);
    expect(find.text('武道四重'), findsNothing);
  });

  testWidgets('切换门派：曼陀山庄显示官网未收录占位', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('曼陀山庄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('曼陀山庄'));
    await tester.pumpAndSettle();

    expect(find.text('曼陀山庄'), findsNWidgets(2));
    expect(find.text('官网资料站暂未收录该门派武道数据'), findsOneWidget);
    expect(find.textContaining('曼陀山庄与慕容（重制）官网页面暂未提供'), findsOneWidget);
  });
}
