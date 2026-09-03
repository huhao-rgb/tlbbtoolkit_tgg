import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_suit_page.dart';

/// 以完整主题（含 TgColors extension）泵入套装图鉴页。
Future<void> pumpPage(WidgetTester tester, {Size size = const Size(1180, 900)}) async {
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

void main() {
  testWidgets('默认渲染：页头 + 视图 chips + 6 张套装卡（图鉴）', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('宝宝套装图鉴'), findsWidgets); // 页头 + 可能重复
    expect(find.textContaining('六大性格套装的件数效果'), findsOneWidget);

    // 视图 chips
    expect(find.text('套装图鉴'), findsOneWidget);
    expect(find.text('材料计算器'), findsOneWidget);

    // 6 张套装卡（卡片名）
    for (final name in ['勇猛套装', '胆小套装', '谨慎套装', '精明套装', '忠诚套装', '内敛套装']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }

    // 分类标签
    for (final cat in ['外功输出', '灵巧输出', '生存防护', '内功输出', '守护辅助', '爆发会心']) {
      expect(find.text(cat), findsOneWidget, reason: cat);
    }

    // 默认 85 档：件数效果 + 底部档位
    expect(find.text('2 件'), findsNWidgets(6));
    expect(find.text('3 件'), findsNWidgets(6));
    expect(find.text('85 级档'), findsNWidgets(6));

    // 适配标签
    expect(find.text('勇猛性格'), findsOneWidget);
    expect(find.text('外功型宝宝'), findsOneWidget);

    // 无溢出
    expect(tester.takeException(), isNull);
  });

  testWidgets('卡片档位切换：切到 95 档后件数效果与底部档位更新', (tester) async {
    await pumpPage(tester);

    // 默认 85：外功攻击 +3%
    expect(find.text('外功攻击 +3%'), findsOneWidget);
    expect(find.text('85 级档'), findsNWidgets(6));

    // 第一张卡（勇猛）切到 95
    await tester.tap(find.text('95').first);
    await tester.pumpAndSettle();

    // 勇猛 95：外功攻击 +4% / 会心伤害 +11%，命中 +3%
    expect(find.text('外功攻击 +4%'), findsOneWidget);
    expect(find.text('会心伤害 +11%，命中 +3%'), findsOneWidget);
    expect(find.text('95 级档'), findsOneWidget);
    expect(find.text('85 级档'), findsNWidgets(5)); // 其余卡仍 85
  });

  testWidgets('点击卡片弹出五件套部件弹窗，可切换档位并关闭', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('勇猛套装'));
    await tester.pumpAndSettle();

    // 弹窗内容：五件套部件 + 主属性（85 档默认）
    expect(find.text('五件套部件'), findsOneWidget);
    expect(find.text('赤焰·裂空盔'), findsOneWidget);
    expect(find.text('副词条 · 力量 +11'), findsOneWidget); // 85 档
    expect(find.text('外功攻击 +86'), findsOneWidget); // 85 档
    expect(find.text('赤焰·吞霄甲'), findsOneWidget);

    // 适配
    expect(find.text('适配：'), findsOneWidget);

    // 弹窗内切档位到 95：部件属性更新
    await tester.tap(find.text('95').last);
    await tester.pumpAndSettle();
    expect(find.text('副词条 · 力量 +15'), findsOneWidget);
    expect(find.text('外功攻击 +118'), findsOneWidget);

    // 关闭
    await tester.tap(find.byType(IconButton).first); // 无障碍关闭
    await tester.pumpAndSettle();
    expect(find.text('五件套部件'), findsNothing);
  });

  testWidgets('材料计算器：默认 85/0 星/含兑换，展示兑换+升星+合计', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();

    // 控件
    expect(find.text('套装档位'), findsOneWidget);
    expect(find.text('当前星级'), findsOneWidget);
    expect(find.text('含兑换材料'), findsOneWidget);

    // 兑换 85 级套装 · 5 件
    expect(find.text('兑换 85 级套装 · 5 件'), findsOneWidget);
    expect(find.text('玄铁令'), findsOneWidget);
    expect(find.text('× 40'), findsOneWidget); // 8×5
    expect(find.text('锻魂石'), findsOneWidget);
    expect(find.text('× 20'), findsOneWidget); // 4×5
    expect(find.text('银两'), findsWidgets);
    expect(find.text('× 75万'), findsOneWidget); // 150000×5

    // 升星 0★ → 5★
    expect(find.text('升星 0★ → 5★ · 85 级 · 5 件'), findsOneWidget);
    expect(find.text('1★'), findsWidgets);
    expect(find.text('5★'), findsWidgets);

    // 合计
    expect(find.text('合计消耗'), findsOneWidget);
  });

  testWidgets('材料计算器：切换档位到 95 / 关闭含兑换 / 改星级', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();

    // 切到 95 档：兑换 95 级套装，银两 400000×5=200万
    await tester.tap(find.text('95').first);
    await tester.pumpAndSettle();
    expect(find.text('兑换 95 级套装 · 5 件'), findsOneWidget);
    expect(find.text('赤金令'), findsOneWidget);
    expect(find.text('× 80'), findsOneWidget); // 16×5
    expect(find.text('× 200万'), findsOneWidget); // 400000×5

    // 关闭含兑换：兑换区消失
    await tester.tap(find.text('含兑换材料'));
    await tester.pumpAndSettle();
    expect(find.text('兑换 95 级套装 · 5 件'), findsNothing);
    expect(find.text('赤金令'), findsNothing);

    // 改星级到 2★：升星标题变化（只算 3★→5★）
    await tester.tap(find.text('2★'));
    await tester.pumpAndSettle();
    expect(find.text('升星 2★ → 5★ · 95 级 · 5 件'), findsOneWidget);
  });

  testWidgets('移动端窄屏：单列卡片不溢出，可切换视图', (tester) async {
    await pumpPage(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    // 图鉴卡片仍可见（单列）
    expect(find.text('勇猛套装'), findsOneWidget);

    // 切到材料计算器
    await tester.tap(find.text('材料计算器'));
    await tester.pumpAndSettle();
    expect(find.text('合计消耗'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
