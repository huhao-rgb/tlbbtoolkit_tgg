import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_suit_page.dart';
import 'package:tlbbtoolkit/shared/widgets/tg_icon.dart';

/// 以完整主题（含 TgColors extension）泵入套装图鉴页。
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
      home: const Scaffold(body: PetSuitPage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// 弹窗右上角关闭按钮（TgIcon('x')）。
final Finder _closeIcon = find.byWidgetPredicate(
  (w) => w is TgIcon && w.name == 'x',
);

void main() {
  testWidgets('默认渲染：页头 + 视图 chips + 85 档 9 张系列卡', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('宝宝套装图鉴'), findsWidgets);
    expect(find.textContaining('22 个珍兽套装系列'), findsOneWidget);

    // 视图 chips
    expect(find.text('套装图鉴'), findsOneWidget);
    expect(find.text('材料计算器'), findsOneWidget);

    // 档位 chips + 系列数
    expect(find.text('共 9 个系列'), findsOneWidget);

    // 85 档 9 个系列
    for (final name in [
      '猛虎越山·勇',
      '猛虎越山·狡',
      '猛虎越山·慎',
      '飞鹰翔空·狡',
      '飞鹰翔空·怯',
      '飞鹰翔空·慎',
      '巨熊哮路·忠',
      '巨熊哮路·慎',
      '奔马逐风·慎',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }

    // 类型 tag（85 档：外功 3 / 内功 3 / 体力 2 / 身法 1）
    expect(find.text('外功'), findsNWidgets(3));
    expect(find.text('内功'), findsNWidgets(3));
    expect(find.text('体力'), findsNWidgets(2));
    expect(find.text('身法'), findsOneWidget);

    // 全套效果与项圈出战效果
    expect(find.text('增加痛击技能的伤害'), findsOneWidget);
    expect(find.text('出战后提升灵气、体力'), findsOneWidget);

    // 底部档位
    expect(find.text('85 级档'), findsNWidgets(9));

    // 无溢出
    expect(tester.takeException(), isNull);
  });

  testWidgets('切到 75 档：系列与数量更新', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('75 级套装'));
    await tester.pumpAndSettle();

    expect(find.text('共 4 个系列'), findsOneWidget);
    for (final name in ['黄雀戏水·怯', '苍狼啸月·勇', '苍狼啸月·狡', '乌豚望日·忠']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('猛虎越山·勇'), findsNothing);
    // 75 档才有散件属性方向
    expect(find.text('内功攻击 · 灵气 · 命中'), findsOneWidget);
    expect(find.text('75 级档'), findsNWidgets(4)); // 4 张卡（chip 文案为「75 级套装」）
  });

  testWidgets('点击卡片弹出五件套部件弹窗（含圣兽鳞消耗）', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('猛虎越山·勇'));
    await tester.pumpAndSettle();

    // 弹窗内容
    expect(find.text('五件套部件'), findsOneWidget);
    for (final slot in ['珍兽面甲', '珍兽武器', '珍兽体甲', '珍兽项圈', '珍兽护符']) {
      expect(find.text(slot), findsOneWidget, reason: slot);
    }
    expect(find.text('出战后提升力量、体力'), findsWidgets);
    expect(find.text('穿齐 5 件效果'), findsOneWidget);
    expect(find.text('增加猛击技能的释放几率'), findsNWidgets(2)); // 卡片 + 弹窗
    expect(find.text('圣兽鳞消耗 · 85 级档'), findsOneWidget);
    expect(find.text('兑换 1★（每件）'), findsOneWidget);
    expect(find.text('30 个'), findsOneWidget);
    expect(find.text('16 / 18 / 20 / 24 个'), findsOneWidget);
    expect(find.text('108 个'), findsOneWidget);
    expect(find.text('540 个'), findsOneWidget);
    expect(find.text('20 / 30 / 35 / 42 / 57'), findsOneWidget);
    expect(find.text('适配：'), findsOneWidget);
    expect(find.text('外功型 · 勇猛性格'), findsOneWidget);

    // 关闭
    await tester.tap(_closeIcon);
    await tester.pumpAndSettle();
    expect(find.text('五件套部件'), findsNothing);
  });

  testWidgets('材料计算器：默认 85 档 / 目标 5★ / 含兑换 → 540 圣兽鳞', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();

    // 控件
    expect(find.text('套装档位'), findsOneWidget);
    expect(find.text('目标星级'), findsOneWidget);
    expect(find.text('含兑换材料'), findsOneWidget);

    // 兑换 1★ 整套
    expect(find.text('兑换 85 级套装 1★ · 5 件'), findsOneWidget);
    expect(find.text('圣兽鳞'), findsWidgets);
    expect(find.text('× 150 个'), findsOneWidget); // 30 × 5
    expect(find.text('每件 30 个'), findsOneWidget);

    // 升星逐星（1★ → 目标 5★）
    expect(find.text('升星 1★ → 5★ · 85 级 · 5 件'), findsOneWidget);
    expect(find.text('每件 ×16 个　·　5 件 ×80 个'), findsOneWidget);
    expect(find.text('每件 ×24 个　·　5 件 ×120 个'), findsOneWidget);

    // 合计
    expect(find.text('合计消耗'), findsOneWidget);
    expect(find.text('× 540 个'), findsOneWidget);
  });

  testWidgets('材料计算器：目标星级越高，消耗越大（1★ → 5★）', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();

    // 默认 5★：兑换 + 全部升星
    expect(find.text('升星 1★ → 5★ · 85 级 · 5 件'), findsOneWidget);
    expect(find.text('× 540 个'), findsOneWidget);

    // 目标 1★：只需兑换
    await tester.tap(find.text('1★'));
    await tester.pumpAndSettle();
    expect(find.text('目标 1★：只需兑换 1★ 整套，无需升星。'), findsOneWidget);
    expect(find.text('每件 ×16 个　·　5 件 ×80 个'), findsNothing);
    expect(find.text('× 150 个'), findsNWidgets(2)); // 兑换行 + 合计行

    // 目标 3★：150 + 80 + 90 = 320
    await tester.tap(find.text('3★'));
    await tester.pumpAndSettle();
    expect(find.text('升星 1★ → 3★ · 85 级 · 5 件'), findsOneWidget);
    expect(find.text('每件 ×18 个　·　5 件 ×90 个'), findsOneWidget);
    expect(find.text('每件 ×24 个　·　5 件 ×120 个'), findsNothing);
    expect(find.text('× 320 个'), findsOneWidget);
  });

  testWidgets('材料计算器：切 95 档 / 关兑换 / 升满 1425', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();

    // 切到 95 档
    await tester.tap(find.text('95'));
    await tester.pumpAndSettle();
    expect(find.text('兑换 95 级套装 1★ · 5 件'), findsOneWidget);
    expect(find.text('× 500 个'), findsOneWidget); // 100 × 5
    expect(find.textContaining('兑换 + 升满 5★」共 1425 个'), findsOneWidget);
    expect(find.text('× 1425 个'), findsOneWidget);

    // 关闭含兑换材料 → 只剩升星
    await tester.tap(find.text('含兑换材料'));
    await tester.pumpAndSettle();
    expect(find.text('兑换 95 级套装 1★ · 5 件'), findsNothing);
    expect(find.text('× 500 个'), findsNothing);
    expect(find.text('× 925 个'), findsOneWidget); // 只剩升星
  });

  testWidgets('移动端窄屏：单列卡片不溢出，可切换视图', (tester) async {
    await pumpPage(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('猛虎越山·勇'), findsOneWidget);

    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();
    expect(find.text('合计消耗'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 窄屏弹窗同样不溢出
    await tester.tap(find.text('套装图鉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('猛虎越山·勇'));
    await tester.pumpAndSettle();
    expect(find.text('五件套部件'), findsOneWidget);
    expect(find.text('540 个'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
