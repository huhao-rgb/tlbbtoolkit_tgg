import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_calc_page.dart';

/// 以完整主题（含 TgColors extension）泵入宝宝资质计算页。
Future<void> pumpPage(WidgetTester tester, {Size size = const Size(1180, 900)}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: PetCalcPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 表单 + 步进器默认值', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('宝宝资质计算'), findsOneWidget);
    expect(find.textContaining('输入当前资质与悟灵状态'), findsOneWidget);

    // 表单标签（用「（…」后缀区分页头副标题中的同名词语）
    expect(find.textContaining('宝宝品种'), findsOneWidget);
    expect(find.textContaining('超灵品种'), findsWidgets); // 开关 label + 行 hint
    expect(find.textContaining('当前资质（攻击'), findsOneWidget);
    expect(find.textContaining('当前悟性（反推'), findsOneWidget);
    expect(find.textContaining('当前灵性（反推'), findsOneWidget);
    expect(find.textContaining('目标悟性（10级'), findsOneWidget);
    expect(find.textContaining('目标灵性（10级'), findsOneWidget);

    // 当前资质输入框默认 2200
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '2200',
    );

    // 步进器默认值：当前 0 / 0 · 目标 8 / 5
    expect(find.text('8'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // 初始未计算：结果卡隐藏（无「预估成品资质」）
    expect(find.text('预估成品资质'), findsNothing);
  });

  testWidgets('开始计算后展示结果卡与明细', (tester) async {
    await pumpPage(tester);

    // 滚动到按钮并点击「开始计算」
    final calcBtn = find.text('开始计算');
    await tester.ensureVisible(calcBtn);
    await tester.pumpAndSettle();
    await tester.tap(calcBtn);
    await tester.pumpAndSettle();

    // 结果卡出现
    expect(find.text('预估成品资质'), findsOneWidget);
    // 默认 2200 / 0-0 → 8-5 → 3016，C 一般，+37%
    expect(find.text('3,016'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.textContaining('一般'), findsWidgets);
    expect(find.textContaining('+37%'), findsWidgets);
    expect(find.text('2,200'), findsOneWidget); // 推算裸资质
    expect(find.textContaining('目标悟性 / 灵性'), findsOneWidget);
    expect(find.textContaining('建议更换胚子再培养'), findsOneWidget);
    // 公式说明
    expect(find.textContaining('官方系数表公式'), findsOneWidget);
  });

  testWidgets('修改输入后计算结果同步更新', (tester) async {
    await pumpPage(tester);

    // 超灵开关 + 目标悟性/灵性都到 10
    await tester.tap(find.text('超灵品种'));
    await tester.pumpAndSettle();

    // 步进器 ＋ 顺序：当前悟性 / 当前灵性 / 目标悟性 / 目标灵性
    // 目标悟性 8 → 10（点两次）
    await tester.tap(find.text('＋').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('＋').at(2));
    await tester.pumpAndSettle();
    // 目标灵性 5 → 10（点 5 次）
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('＋').at(3));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.text('开始计算'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始计算'));
    await tester.pumpAndSettle();

    // 2200 超灵 0-0 → 10-10 = round(2200*1.393*1.34)=4106.97→4107
    // （预估成品资质 与 满悟满灵估算 均为 4,107）
    expect(find.text('4,107'), findsNWidgets(2));
    expect(find.textContaining('超灵品种（灵10 +34%）'), findsOneWidget);
    expect(find.textContaining('悟性+39.3% / 灵性+34%'), findsWidgets);
  });

  testWidgets('移动端窄屏：单列堆叠，不溢出', (tester) async {
    await pumpPage(tester, size: const Size(390, 844));

    // 无水平溢出（布局异常会抛 Overflow）
    expect(tester.takeException(), isNull);
    expect(find.text('宝宝资质计算'), findsOneWidget);

    // 步进器仍可用
    final calcBtn = find.text('开始计算');
    await tester.ensureVisible(calcBtn);
    await tester.pumpAndSettle();
    await tester.tap(calcBtn);
    await tester.pumpAndSettle();
    expect(find.text('预估成品资质'), findsOneWidget);
  });
}
