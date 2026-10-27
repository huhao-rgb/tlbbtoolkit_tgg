import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/pet/presentation/pages/pet_prob_page.dart';

/// 以完整主题（含 TgColors extension）泵入技能概率页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 900),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: TgTheme.dark,
        darkTheme: TgTheme.dark,
        home: const Scaffold(body: PetProbPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 性格/系别 chips + 16 技能行 + 系数表', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('珍兽技能释放概率'), findsOneWidget);
    expect(find.textContaining('五系技能的发动概率'), findsOneWidget);

    // 性格 chips：五种性格（系数表表头同名，故各出现 2 次）
    for (final name in ['胆小', '谨慎', '忠诚', '精明', '勇猛']) {
      expect(find.text(name), findsNWidgets(2), reason: '$name chip + 系数表表头');
    }
    // 「通用」「内敛」都不是游戏内性格，不出现
    expect(find.text('通用'), findsNothing);
    expect(find.text('内敛'), findsNothing);

    // 系别 chips（只列技能库里有的系）+ 每行系别 tag + 系数表行名
    expect(find.text('全部'), findsOneWidget);
    // 报复 / 防御：6 个技能 tag + chip + 系数表行 = 8；护主：4 + chip + 行 = 6
    for (final (name, count) in [('报复', 8), ('防御', 8), ('护主', 6)]) {
      expect(
        find.text(name),
        findsNWidgets(count),
        reason: '$name chip + 系数表行 + 技能 tag',
      );
    }
    // 技能库没有物攻/法攻数据，不出现 chip
    expect(find.text('物攻'), findsOneWidget); // 仅系数表行
    expect(find.text('法攻'), findsOneWidget);

    // 表头
    expect(find.text('技能'), findsOneWidget);
    expect(find.text('系别'), findsOneWidget);
    expect(find.text('触发概率'), findsOneWidget);
    expect(find.text('判定'), findsOneWidget);

    // 默认选中首项「胆小」：报复 ×0.5 → 10%/15% 各 3 个；防御 ×1 → 20%/30% 各 3 个；
    // 护主 ×0.5 → 忠心 3.5→4%、高级忠心 6%、灵气 7.5→8%、高级灵气 12.5→13%
    expect(find.text('10%'), findsNWidgets(3));
    expect(find.text('15%'), findsNWidgets(3));
    expect(find.text('20%'), findsNWidgets(3));
    expect(find.text('30%'), findsNWidgets(3));
    expect(find.text('4%'), findsOneWidget);
    expect(find.text('6%'), findsOneWidget);
    expect(find.text('8%'), findsOneWidget);
    expect(find.text('13%'), findsOneWidget);

    // 16 个技能（有描述，用 desc 定位）
    for (final name in ['反击', '吸血', '反震', '灵动', '吸魔', '打怒', '忠心', '灵气']) {
      expect(find.textContaining(name), findsWidgets, reason: '$name 应出现在列表中');
    }
    expect(find.textContaining('受击时一定几率反击'), findsOneWidget);
    expect(find.textContaining('主人受击时替主人承伤'), findsOneWidget);

    // 系数表（图片顶表）
    expect(find.text('性格发动系数'), findsOneWidget);
    expect(find.text('技能系'), findsOneWidget);
    // 系数矩阵中 1.3 出现 4 次（物攻精明 / 法攻谨慎 / 护主谨慎 / 报复勇猛）
    expect(find.text('1.3'), findsNWidgets(4));
    // 0.5 / 0.8 / 2 各出现 5 次
    for (final v in ['0.5', '0.8', '2']) {
      expect(find.text(v), findsNWidgets(5), reason: '系数 $v');
    }

    // 公式说明
    expect(find.textContaining('基础概率 × 性格发动系数'), findsOneWidget);
  });

  testWidgets('性格筛选：切到精明后报复类翻倍（高级反击 60%）', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('精明').first);
    await tester.pumpAndSettle();

    // 报复 ×2 → 40%（普通）/ 60%（高级）各 3 个
    expect(find.text('40%'), findsNWidgets(3));
    expect(find.text('60%'), findsNWidgets(3));
    // 防御 ×0.8 → 16%（普通）/ 24%（高级）各 3 个
    expect(find.text('16%'), findsNWidgets(3));
    expect(find.text('24%'), findsNWidgets(3));
    // 护主 ×1 → 基础概率不变：7 / 12 / 15 / 25
    expect(find.text('7%'), findsOneWidget);
    expect(find.text('12%'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('系别筛选：只选报复时防御/护主技能隐藏', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('报复').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('受击时反弹伤害'), findsOneWidget); // 反震
    expect(find.textContaining('受击时提升闪避'), findsNothing); // 灵动（防御）
    expect(find.textContaining('主人受击时替主人承伤'), findsNothing); // 忠心（护主）
    // 报复 6 个技能（默认胆小 ×0.5）→ 10% / 15% 各 3 个
    expect(find.text('10%'), findsNWidgets(3));
    expect(find.text('15%'), findsNWidgets(3));
  });

  testWidgets('系别+性格组合：防御 + 谨慎 → 灵动 40% / 高级灵动 60%', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('防御').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('谨慎').first);
    await tester.pumpAndSettle();

    // 防御 ×2：20*2=40、30*2=60，各 3 个
    expect(find.text('40%'), findsNWidgets(3));
    expect(find.text('60%'), findsNWidgets(3));
  });

  testWidgets('详情弹窗：显示基础概率 / 性格概率 / 发动系数', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('精明').first);
    await tester.pumpAndSettle();

    // 打开首行「反击」详情（精明：20% × 2 = 40%）；表头也有「详情」，故取第 2 个
    await tester.tap(find.text('详情').at(1));
    await tester.pumpAndSettle();

    expect(find.text('基础概率'), findsOneWidget);
    expect(find.text('精明性格概率'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('报复系数'), findsOneWidget);
    expect(find.textContaining('受击判定'), findsWidgets);
  });

  testWidgets('移动端窄屏：单列列表不溢出，chips 可切换', (tester) async {
    await pumpPage(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('珍兽技能释放概率'), findsOneWidget);
    // 移动端表头隐藏
    expect(find.text('触发概率'), findsNothing);

    // 仍可切换性格与系别
    await tester.tap(find.text('胆小').first);
    await tester.pumpAndSettle();
    expect(find.text('10%'), findsNWidgets(3));

    await tester.tap(find.text('护主').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('主人受击时替主人承伤'), findsOneWidget);
    expect(find.textContaining('受击时一定几率反击'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面端 tag 按内容自适应宽度，不撑满整列', (tester) async {
    await pumpPage(tester, size: const Size(1180, 900));

    // 以「受击判定」tag（6 行共现）为例：向上找紧包文字的胶囊容器。
    final tagText = find.text('受击判定').first;
    final tagContainer = tester
        .widgetList<Container>(
          find.ancestor(of: tagText, matching: find.byType(Container)),
        )
        .firstWhere(
          (c) =>
              c.padding ==
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        );

    final tagSize = tester.getSize(find.byWidget(tagContainer));
    final textSize = tester.getSize(tagText);

    expect(tagSize.width, greaterThan(textSize.width));
    expect(tagSize.width, lessThan(textSize.width + 24));

    // 判定列按 flex 55/405 分配；tag 内容宽应远小于列宽（未撑满）。
    final pageWidth = tester.getSize(find.byType(PetProbPage)).width;
    final colWidth = pageWidth * 55 / 405;
    expect(tagSize.width, lessThan(colWidth * 0.6));
  });
}
