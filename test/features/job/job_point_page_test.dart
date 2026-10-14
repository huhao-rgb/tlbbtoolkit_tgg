import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/domain/job_point.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_point_page.dart';

/// 以完整主题（含 TgColors extension）泵入职业加点计算器页。
Future<void> pumpPage(
  WidgetTester tester, {
  Size size = const Size(1180, 1000),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: JobPointPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('domain', () {
    test('总潜能：119 级 → 545；10 级 → 0；越界 clamp', () {
      expect(totalPoints(119), 545);
      expect(totalPoints(10), 0);
      expect(totalPoints(60), 250);
      expect(totalPoints(200), 545);
      expect(totalPoints(5), 0);
    });

    test('一键推荐：逍遥权重按 ling/shen/ti 分配且合计=545', () {
      final pts = recommendPoints('xiaoyao', 545);
      expect(pts.values.fold<int>(0, (a, b) => a + b), 545);
      expect(pts['ling']!, greaterThan(pts['shen']!));
      expect(pts['shen']!, greaterThan(pts['ti']!));
      expect(pts['li'], 0);
      expect(pts['ding'], 0);
    });

    test('面板预览公式：逍遥成长系数', () {
      expect(jobGrowthOf('xiaoyao')['hp']!.value, 50);
      expect(jobGrowthOf('xiaoyao')['nei']!.value, 7.6715);

      final p = computePreview('xiaoyao', 119, {
        'li': 0,
        'ling': 100,
        'ti': 100,
        'ding': 0,
        'shen': 100,
      });
      expect(p.hp, 119 * 28 + 100 * 50);
      expect(p.mp, 119 * 20 + 0 * 36);
      expect(p.atkP, closeTo(100 * 7.6715, 1e-9));
      expect(p.atkW, 0);
      expect(p.hit, 119 * 7 + 100 * 7.5);
      expect(p.dodge, 119 * 5 + 100 * 4);
      expect(p.crit, closeTo(100 * (0.05 + 0.05), 1e-9));
    });

    test('面板预览：门派系数不同 → 结果不同（少林体力/明教力量）', () {
      final pts = {'li': 100, 'ling': 0, 'ti': 100, 'ding': 0, 'shen': 0};
      final shaolin = computePreview('shaolin', 100, pts);
      final mingjiao = computePreview('mingjiao', 100, pts);
      expect(shaolin.hp, closeTo(100 * 28 + 100 * 71.5, 1e-9));
      expect(mingjiao.hp, closeTo(100 * 28 + 100 * 55.2, 1e-9));
      expect(shaolin.atkW, closeTo(100 * 7.6, 1e-9));
      expect(mingjiao.atkW, closeTo(100 * 8.3, 1e-9));
    });

    test('未知门派成长系数回退逍遥', () {
      expect(jobGrowthOf('nope')['hp']!.value, 50);
    });

    test('成长系数条目 8 项且覆盖十二门派', () {
      expect(kJobGrowthFields.length, 8);
      // 键集合需与门派列表严格一致（避免拼错 key 导致静默回退逍遥）
      expect(kJobGrowth.keys.toSet(), {for (final s in kJobSects) s.key});
      for (final s in kJobSects) {
        final g = kJobGrowth[s.key];
        expect(g, isNotNull, reason: s.key);
        for (final f in kJobGrowthFields) {
          expect(g![f.key], isNotNull, reason: '${s.key}.${f.key}');
        }
      }
    });

    test('千分位', () {
      expect(formatThousand(3332), '3,332');
      expect(formatThousand(0), '0');
      expect(formatThousand(1234567), '1,234,567');
    });

    test('面板数值格式化：千分位 / 1 位小数 / 会心 2 位小数', () {
      // toLocaleString：千分位 + 最多 3 位小数
      expect(formatGrouped(3332), '3,332');
      expect(formatGrouped(0), '0');
      expect(formatGrouped(707.3224), '707.322');
      expect(formatGrouped(52 * 71.5), '3,718');
      // toFixed(1) 去尾
      expect(formatFixed1(0), '0');
      expect(formatFixed1(100 * 7.6715), '767.1');
      expect(formatFixed1(100 * 7.6), '760');
      // Math.round(v*100)/100
      expect(formatCrit(0), '0');
      expect(formatCrit(100 * 0.1), '10');
      expect(formatCrit(3.4000000000000004), '3.4');
      // 成长系数展示文本
      expect(const JobGrowthValue(25).display, '25');
      expect(const JobGrowthValue(7.6, approx: true).display, '≈7.6');
    });
  });

  testWidgets('默认渲染：等级119 / 总545 / 五行 / 面板预览', (tester) async {
    await pumpPage(tester);

    expect(find.text('职业加点计算器'), findsWidgets);
    expect(find.textContaining('潜能点分配 · 一键推荐方案'), findsOneWidget);

    // 剩余/总潜能 545
    expect(find.text('545'), findsNWidgets(2));
    expect(find.text('一键推荐'), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);

    // 五行名
    for (final name in ['力量', '灵气', '体力', '定力', '身法']) {
      expect(find.text(name), findsOneWidget);
    }

    // 面板预览标题 + 门派名
    expect(find.text('面板预览 · '), findsOneWidget);
    expect(find.text('逍遥'), findsNWidgets(2)); // pill + 预览标题

    // 预览初值（119 级，无加点）
    expect(find.text('3,332'), findsOneWidget); // 气血
    expect(find.text('2,380'), findsOneWidget); // 气
    expect(find.text('833'), findsOneWidget); // 命中
    expect(find.text('595'), findsOneWidget); // 闪避

    // 会心攻击（7 项预览之一）
    expect(find.text('会心攻击'), findsOneWidget);

    // 门派成长系数（逍遥全为实测精确值 → 无 ≈ 标注）
    expect(find.text('门派成长系数 · 每点潜能换算'), findsOneWidget);
    expect(find.text('体力 → 血上限'), findsOneWidget);
    expect(find.text('力量 → 外功攻击'), findsOneWidget);
    expect(find.text('身法 → 会心防御'), findsOneWidget);
    expect(find.text('50'), findsOneWidget); // 逍遥 体力 → 血上限
    expect(find.text('7.6715'), findsOneWidget); // 逍遥 灵气 → 内功攻击
    // 说明文字里也含 ≈，故用行首锚定，只校验系数条目的近似标注
    expect(find.textContaining(RegExp('^≈')), findsNothing);
  });

  testWidgets('点击 ＋ 分配潜能：剩余减少、预览更新', (tester) async {
    await pumpPage(tester);

    // 体力行 = 第 3 个 ＋ 按钮（五行按力量/灵气/体力/定力/身法）
    final plus = find.text('＋');
    await tester.tap(plus.at(2));
    await tester.pump();

    // 剩余 544 / 总 545
    expect(find.text('544'), findsOneWidget);
    // 面板：气血 = 3332 + 逍遥体力系数 50 = 3382
    expect(find.text('3,382'), findsOneWidget);
  });

  testWidgets('滑块上限 = 剩余潜能：拖满后其他维度不可再分配', (tester) async {
    await pumpPage(tester);

    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(5)); // 力量/灵气/体力/定力/身法

    // 体力（第 3 行）拖到最右 → 吃满 545
    await tester.drag(sliders.at(2), const Offset(2000, 0));
    await tester.pump();
    expect(tester.widget<Slider>(sliders.at(2)).value, 545);
    // 剩余 0（「545」只剩行内数值 + 顶部「总」）
    expect(find.text('545'), findsNWidgets(2));
    // 面板：气血 = 3332 + 545 × 50
    expect(find.text('30,582'), findsOneWidget);

    // 其他维度上限被剩余潜能压到 0 → 滑块禁用、拖动无效
    final li = tester.widget<Slider>(sliders.at(0));
    expect(li.value, 0);
    expect(li.onChanged, isNull);
    await tester.drag(sliders.at(0), const Offset(2000, 0));
    await tester.pump();
    expect(tester.widget<Slider>(sliders.at(0)).value, 0);

    // 已分配的体力仍可回拖
    expect(tester.widget<Slider>(sliders.at(2)).onChanged, isNotNull);
    await tester.drag(sliders.at(2), const Offset(-2000, 0));
    await tester.pump();
    expect(tester.widget<Slider>(sliders.at(2)).value, 0);
    expect(find.text('545'), findsNWidgets(2)); // 回到「剩余 545 / 总 545」
  });

  testWidgets('总潜能为 0（10 级）：滑块全部禁用', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), '10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final sliders = find.byType(Slider);
    for (var i = 0; i < 5; i++) {
      final s = tester.widget<Slider>(sliders.at(i));
      expect(s.value, 0, reason: 'row $i');
      expect(s.onChanged, isNull, reason: 'row $i');
    }
    expect(find.text('545'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切门派后成长系数与预览同步（少林 ≈ 近似标注）', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('少林'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('少林'));
    await tester.pumpAndSettle();

    // 少林成长系数：体力 → 血上限 71.5（精确）、力量 → 外功攻击 ≈7.6（近似）
    expect(find.text('71.5'), findsOneWidget);
    expect(find.text('≈7.6'), findsOneWidget);

    // 面板预览无加点仍为等级基线
    expect(find.text('3,332'), findsOneWidget);
  });

  testWidgets('一键推荐 → 合计 545 分配，清空归零', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('一键推荐'));
    await tester.pump();

    // 推荐后剩余为 0（总值仍 545）
    expect(find.text('545'), findsOneWidget); // 仅「总」
    expect(find.text('0'), findsWidgets);

    // 清空 → 剩余恢复 545
    await tester.tap(find.text('清空'));
    await tester.pump();
    expect(find.text('545'), findsNWidgets(2));
  });

  testWidgets('切门派后一键推荐用新权重（少林 → 力量最高）', (tester) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.text('少林'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('少林'));
    await tester.pumpAndSettle();

    expect(find.text('少林'), findsNWidgets(2)); // pill + 预览标题

    await tester.tap(find.text('一键推荐'));
    await tester.pump();

    // 少林权重 li 最高，力量加点多；外功攻击 = 246 × 7.6 = 1,869.6
    expect(find.text('外功攻击'), findsOneWidget);
    expect(find.text('1,869.6'), findsNothing); // 外功攻击用 toFixed(1) 去千分位
    expect(find.text('1869.6'), findsOneWidget);
    // 气血 = 3332 + 191 × 71.5 = 16,988.5
    expect(find.text('16,988.5'), findsOneWidget);
  });

  testWidgets('紧凑宽度（560 / 390）：预览与成长系数自动换列不溢出', (tester) async {
    for (final size in const [Size(560, 900), Size(390, 900)]) {
      await pumpPage(tester, size: size);

      expect(find.text('门派成长系数 · 每点潜能换算'), findsOneWidget);
      expect(find.text('体力 → 血上限'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
