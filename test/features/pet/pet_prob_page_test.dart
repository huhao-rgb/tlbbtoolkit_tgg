import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_prob_page.dart';

/// 以完整主题（含 TgColors extension）泵入技能概率页。
Future<void> pumpPage(WidgetTester tester, {Size size = const Size(1180, 900)}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: PetProbPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 性格/分类 chips + 10 技能行', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('宝宝技能释放概率'), findsOneWidget);
    expect(find.textContaining('按性格查看自动'), findsOneWidget);

    // 性格 chips
    for (final name in ['通用', '勇猛', '胆小', '谨慎', '精明', '忠诚', '内敛']) {
      expect(find.text(name), findsOneWidget);
    }
    // 分类 chips
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('攻击类'), findsOneWidget);
    expect(find.text('状态类'), findsOneWidget);
    expect(find.text('辅助类'), findsOneWidget);

    // 表头
    expect(find.text('技能'), findsOneWidget);
    expect(find.text('类型'), findsOneWidget);
    expect(find.text('触发概率'), findsOneWidget);
    expect(find.text('判定'), findsOneWidget);

    // 默认通用性格：猛击 20% · 护主 100%
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    // 全部 10 个技能名（有描述的技能经 Text.rich 渲染，用 textContaining 匹配）
    for (final name in ['猛击', '连击', '痛击', '寒冰咒', '烈火咒', '虚弱', '打怒', '迟缓', '吸血', '护主']) {
      expect(find.textContaining(name), findsOneWidget);
    }
    // 公式说明
    expect(find.textContaining('实测基准值 × 性格修正系数'), findsOneWidget);
  });

  testWidgets('性格筛选：切到勇猛后猛击概率变为 26%', (tester) async {
    await pumpPage(tester);

    expect(find.text('20%'), findsOneWidget); // 通用猛击
    await tester.tap(find.text('勇猛'));
    await tester.pumpAndSettle();

    expect(find.text('26%'), findsOneWidget); // 勇猛猛击 20*1.3
    expect(find.text('20%'), findsOneWidget); // 连击 15*1.3=20
  });

  testWidgets('分类筛选：攻击类只剩 5 行', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('攻击类'));
    await tester.pumpAndSettle();

    expect(find.text('猛击'), findsOneWidget);
    expect(find.text('连击'), findsOneWidget);
    expect(find.text('虚弱'), findsNothing); // 状态类隐藏
    expect(find.text('护主'), findsNothing); // 辅助类隐藏
  });

  testWidgets('分类+性格组合：状态类 + 精明 → 虚弱 11%', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('状态类'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('精明'));
    await tester.pumpAndSettle();

    // 虚弱 8*1.4=11.2→11、打怒 8*1.4→11（两个 11%）；迟缓 6*1.4=8.4→8
    expect(find.text('11%'), findsNWidgets(2));
    expect(find.text('8%'), findsOneWidget);
  });

  testWidgets('移动端窄屏：单列列表不溢出，chips 可切换', (tester) async {
    await pumpPage(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('宝宝技能释放概率'), findsOneWidget);
    // 移动端表头隐藏
    expect(find.text('触发概率'), findsNothing);

    // 仍可切换性格与分类
    await tester.tap(find.text('勇猛'));
    await tester.pumpAndSettle();
    expect(find.text('26%'), findsOneWidget);
    await tester.tap(find.text('辅助类'));
    await tester.pumpAndSettle();
    expect(find.textContaining('护主'), findsOneWidget);
    expect(find.text('猛击'), findsNothing);
  });

  testWidgets('桌面端类型 tag 按内容自适应宽度，不撑满整列', (tester) async {
    await pumpPage(tester, size: const Size(1180, 900));

    // 以「自动攻击」tag（猛击/连击/痛击三行共现）为例：
    // 向上找紧包文字的 tag 容器（横向 padding 8 的胶囊）。
    final tagText = find.text('自动攻击').first;
    final tagContainer = tester
        .widgetList<Container>(
          find.ancestor(of: tagText, matching: find.byType(Container)),
        )
        .firstWhere(
          (c) => c.padding == const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        );

    final tagSize = tester.getSize(find.byWidget(tagContainer));
    final textSize = tester.getSize(tagText);

    // 紧凑胶囊：tag 宽 = 文字宽 + 左右 padding(8×2) + 边框(1×2)，而非撑满列。
    expect(tagSize.width, greaterThan(textSize.width));
    expect(tagSize.width, lessThan(textSize.width + 24));

    // 类型列按 flex 75/405 分配；tag 内容宽应远小于列宽（未撑满）。
    final pageWidth = tester.getSize(find.byType(PetProbPage)).width;
    final typeColWidth = pageWidth * 75 / 405;
    expect(tagSize.width, lessThan(typeColWidth * 0.6));
  });
}
