import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_artifact_page.dart';
import 'package:tlbbtoolkit/features/job/presentation/pages/job_sect_intro_page.dart';

Future<void> _pumpArtifact(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: JobArtifactPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSect(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TgTheme.dark,
      darkTheme: TgTheme.dark,
      home: const Scaffold(body: JobSectIntroPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('职业神器页', () {
    testWidgets('默认少林 42 级韦陀伏魔杖 + 基础属性 + 获取途径', (tester) async {
      await _pumpArtifact(tester);

      expect(find.text('职业神器'), findsWidgets);
      expect(find.textContaining('九大门派专属神兵'), findsOneWidget);

      // 门派 pill + 门派名（默认少林）
      expect(find.text('少林'), findsNWidgets(2));
      expect(find.text('外功 · 坦克'), findsOneWidget);

      // 神器卡：武器名 / 等级 tag / 档位
      expect(find.text('韦陀伏魔杖'), findsOneWidget);
      expect(find.text('42 级神器'), findsOneWidget);
      for (final lv in ['42', '62', '82', '102']) {
        expect(find.text(lv), findsOneWidget);
      }

      // 简介
      expect(find.textContaining('少室山精铁所铸'), findsOneWidget);
      expect(find.textContaining('适配武器：禅杖'), findsOneWidget);

      // 基础属性
      expect(find.text('基础属性'), findsOneWidget);
      expect(find.text('攻击'), findsOneWidget);
      expect(find.text('+380'), findsOneWidget);
      expect(find.text('+30'), findsOneWidget);
      expect(find.text('+8'), findsOneWidget);

      // 神兵特性 / 获取途径
      expect(find.textContaining('神兵共鸣'), findsOneWidget);
      expect(find.text('获取途径'), findsOneWidget);
      expect(find.textContaining('欧阳冶处接取'), findsOneWidget);

      // 脚注
      expect(find.textContaining('神器每 20 级一档'), findsOneWidget);
    });

    testWidgets('切换档位到 102 / 切换门派到峨眉', (tester) async {
      await _pumpArtifact(tester);

      // 档位 102
      await tester.tap(find.text('102'));
      await tester.pumpAndSettle();
      expect(find.text('不动明王杖'), findsOneWidget);
      expect(find.text('102 级神器'), findsOneWidget);
      expect(find.text('+320'), findsOneWidget);

      // 切峨眉 → 回到 42 档
      await tester.ensureVisible(find.text('峨眉'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('峨眉'));
      await tester.pumpAndSettle();
      expect(find.text('峨眉'), findsNWidgets(2));
      expect(find.text('灵犀双影剑'), findsOneWidget);
      expect(find.text('42 级神器'), findsOneWidget);
    });
  });

  group('门派介绍页', () {
    testWidgets('默认少林简介 / 特色 / 属性倾向 / 适合人群', (tester) async {
      await _pumpSect(tester);

      expect(find.text('门派介绍'), findsWidgets);
      expect(find.text('少林'), findsNWidgets(2));
      expect(find.text('外功 · 坦克'), findsOneWidget);

      // 简介
      expect(find.textContaining('千年古刹'), findsOneWidget);
      // 门派特色
      expect(find.text('门派特色'), findsOneWidget);
      expect(find.text('定位'), findsOneWidget);
      expect(find.text('外功坦辅'), findsOneWidget);
      expect(find.text('武器'), findsOneWidget);
      // 属性倾向权重
      expect(find.text('属性倾向 · 潜能加点参考'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      // 适合人群
      expect(find.textContaining('适合喜欢正面承伤'), findsOneWidget);
      // 深入这个门派
      expect(find.text('深入这个门派'), findsOneWidget);
      expect(find.text('技能库'), findsOneWidget);
      expect(find.text('神器'), findsOneWidget);
      expect(find.text('武道'), findsOneWidget);
      expect(find.text('加点计算器'), findsOneWidget);
    });

    testWidgets('切换门派到天山 → 内容联动', (tester) async {
      await _pumpSect(tester);

      await tester.ensureVisible(find.text('天山'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('天山'));
      await tester.pumpAndSettle();

      expect(find.text('天山'), findsNWidgets(2));
      expect(find.text('外功 · 刺客'), findsOneWidget);
      expect(find.textContaining('缥缈峰终年积雪'), findsOneWidget);
      expect(find.text('外功刺客'), findsOneWidget);
      // 天山权重：li .45 shen .4 ti .15
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });
  });
}
