import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/app/app.dart';
import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';
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
      expect(find.textContaining('十二大门派专属神兵'), findsOneWidget);

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

    testWidgets('切换门派到曼陀山庄：官网完整神器且不崩溃', (tester) async {
      await _pumpArtifact(tester);

      await tester.ensureVisible(find.text('曼陀山庄'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('曼陀山庄'));
      await tester.pumpAndSettle();

      expect(find.text('曼陀山庄'), findsNWidgets(2)); // pill + 当前门派名
      expect(find.text('内功 · 琴音'), findsOneWidget);
      expect(find.text('玉弦琴'), findsOneWidget); // 42 级官网神器
      expect(find.textContaining('曼陀山庄入门之琴'), findsOneWidget);

      // 切换档位到 102：绿绮琴
      await tester.tap(find.text('102'));
      await tester.pumpAndSettle();
      expect(find.text('绿绮琴'), findsOneWidget);
      expect(find.textContaining('镇庄之宝'), findsOneWidget);
    });
  });

  group('门派介绍页', () {
    testWidgets('默认少林简介 / 主要属性 / 背景 / 特色 / 生活技能 / 属性倾向', (tester) async {
      await _pumpSect(tester);

      expect(find.text('门派介绍'), findsWidgets);
      expect(find.text('少林'), findsNWidgets(2));
      expect(find.text('外功 · 坦克'), findsOneWidget);

      // 简介（官网文案）
      expect(find.textContaining('少林弟子武功底蕴深厚'), findsWidgets);
      // 主要属性（属性攻 / 主修 / 攻系）
      expect(find.text('主要属性'), findsOneWidget);
      expect(find.textContaining('玄攻 · 主属性攻'), findsOneWidget);
      // 背景渊源
      expect(find.text('背景渊源'), findsOneWidget);
      expect(find.textContaining('中原第一名刹'), findsOneWidget);
      // 门派特色（官网版）
      expect(find.text('门派特色'), findsOneWidget);
      expect(find.text('定位'), findsOneWidget);
      expect(find.text('近战攻击，单玄属性'), findsOneWidget);
      expect(find.text('武器'), findsOneWidget);
      // 门派生活技能
      expect(find.text('门派生活技能'), findsOneWidget);
      expect(find.text('开光'), findsWidgets);
      // 属性倾向权重（少林 li .45 ti .35）
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
      expect(find.textContaining('天山弟子的武功以诡异著称'), findsWidgets);
      expect(find.textContaining('灵鹫宫远在天山'), findsOneWidget); // 背景渊源
      // 天山权重：li .45 shen .4 ti .15
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('切换门派到恶人谷：官网完整介绍不崩溃', (tester) async {
      await _pumpSect(tester);

      await tester.ensureVisible(find.text('恶人谷'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('恶人谷'));
      await tester.pumpAndSettle();

      expect(find.text('恶人谷'), findsNWidgets(2));
      expect(find.text('内功 · 刺客'), findsOneWidget);
      expect(find.textContaining('毁誉扰扰皆黄土'), findsWidgets);
      // 无生活技能的门派不显示该区块（不崩溃）
      expect(find.text('门派生活技能'), findsNothing);
    });
  });

  group('门派介绍 → 深入这个门派（跨页定位门派）', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize =
          const Size(1440, 1400) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const TlbbApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('选天龙 → 点「深入·技能库」→ 技能库默认定位天龙', (tester) async {
      await pumpApp(tester);

      // 进入门派介绍页（职业 hub → 门派介绍）
      await tester.tap(find.text('职业').last); // 底部 tab
      await tester.pumpAndSettle();
      await tester.tap(find.text('门派介绍').first);
      await tester.pumpAndSettle();
      expect(find.text('门派介绍'), findsWidgets);

      // 切换到天龙
      await tester.ensureVisible(find.text('天龙'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('天龙'));
      await tester.pumpAndSettle();
      expect(find.textContaining('天龙弟子内、外兼修'), findsWidgets);

      // 点「深入这个门派 → 技能库」
      await tester.ensureVisible(find.text('技能库'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('技能库'));
      await tester.pumpAndSettle();

      // 技能库应默认定位天龙（而非逍遥）
      expect(find.text('职业技能库'), findsWidgets);
      expect(find.text('天龙'), findsNWidgets(2)); // pill + 当前门派名
      expect(find.text('一阳指指法'), findsWidgets);
      expect(find.text('正阳手'), findsWidgets);
      expect(find.text('百花经'), findsNothing);
    });
  });
}
