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
  testWidgets('默认渲染：页头 + 9 门派 + 双路线卡', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('职业武道'), findsWidgets); // 顶栏标题 + h1
    expect(find.textContaining('选择门派，查看攻伐与御守'), findsOneWidget);

    // 9 门派 pill（逍遥还作为当前门派名出现一次）
    for (final name in ['少林', '明教', '丐帮', '天山', '峨眉', '武当', '星宿', '慕容']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('逍遥'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内功 · 控制'), findsOneWidget);

    // 两条路线卡
    expect(find.text('攻伐之道'), findsOneWidget);
    expect(find.text('御守之道'), findsOneWidget);
    // 4 重行
    for (final cn in ['一重', '二重', '三重', '四重']) {
      expect(find.text(cn), findsNWidgets(2));
    }
    expect(find.text('锋芒'), findsOneWidget);
    expect(find.text('铁壁'), findsOneWidget);
    // 技能树按钮 × 8
    expect(find.text('技能树'), findsNWidgets(8));
    // 推荐度与星级
    expect(find.text('推荐度'), findsNWidgets(2));
    // 去加点按钮 × 2
    expect(find.text('去加点'), findsNWidgets(2));
  });

  testWidgets('切换门派：点武当后门派名与定位更新', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('武当'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('武当'));
    await tester.pumpAndSettle();

    expect(find.text('武当'), findsNWidgets(2)); // pill + 当前门派名
    expect(find.text('内功 · 均衡'), findsOneWidget);
  });

  testWidgets('点技能树打开弹窗，显示树节点与解锁说明', (tester) async {
    await pumpPage(tester);

    // 点攻伐之道 · 一重「技能树」（页面中第 1 个）
    final btn = find.text('技能树').first;
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn);
    await tester.pumpAndSettle();

    // 弹窗标题与子标题 tag
    expect(find.text('武道 · 锋芒'), findsWidgets);
    expect(find.text('攻伐之道 · 一重'), findsOneWidget);

    // 树节点（一重：7 个节点）
    expect(find.text('核心节点 · 开启攻伐'), findsOneWidget);
    expect(find.text('锋刃'), findsOneWidget);
    expect(find.text('锐气'), findsOneWidget);
    expect(find.text('破军'), findsOneWidget);
    expect(find.text('蚀甲'), findsOneWidget);
    expect(find.text('聚气'), findsOneWidget);
    expect(find.text('锐不可当'), findsOneWidget);

    // 解锁说明
    expect(find.textContaining('核心节点'), findsWidgets);
    expect(find.textContaining('两大分支'), findsOneWidget);
  });

  testWidgets('御守之道弹窗：二重为盘石树', (tester) async {
    await pumpPage(tester);

    // 御守之道卡片的技能树按钮 = 第 5 个（每卡 4 个）
    final btn = find.text('技能树').at(4);
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(find.text('武道 · 铁壁'), findsWidgets);
    expect(find.text('御守之道 · 一重'), findsOneWidget);
    expect(find.text('核心节点 · 开启御守'), findsOneWidget);
  });
}
