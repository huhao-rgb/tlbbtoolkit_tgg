import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/app/theme/app_theme.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/features/misc/presentation/pages/misc_regress_page.dart';

/// 以完整主题 + ProviderScope（注入 mock prefs）泵入卡回归页。
Future<void> pumpPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(1200, 1000) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: TgTheme.dark,
        darkTheme: TgTheme.dark,
        home: const Scaffold(body: MiscRegressPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认渲染：页头 + 规则 + 空态账号卡 + 未选中提示', (tester) async {
    await pumpPage(tester);

    // 页头
    expect(find.text('卡回归计算器'), findsWidgets); // crumb/h1/info
    expect(find.textContaining('多账号回归周期记录'), findsOneWidget);
    // 规则
    expect(find.textContaining('规则：账号连续'), findsOneWidget);
    // 我的账号卡 + 计数 0 + 添加账号按钮
    expect(find.text('我的账号'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('添加账号'), findsOneWidget);
    expect(find.textContaining('暂无账号'), findsOneWidget);
    // 底部未选中提示
    expect(find.textContaining('在上方选择一个账号'), findsOneWidget);
  });

  testWidgets('添加账号：弹窗输入名称/等级，保存后账号卡出现并进入空闲面板', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    expect(find.text('角色名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '逍遥生');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    // 账号卡出现（名称在卡与选中面板头部各一次）；计数 1；空闲面板可见。
    expect(find.text('逍遥生'), findsWidgets);
    expect(find.textContaining('Lv.89'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('开始回归计时'), findsWidgets);
  });

  testWidgets('开始回归计时后进入倒计时面板', (tester) async {
    await pumpPage(tester);

    // 预置一个账号直接选中并空闲
    // （通过界面添加最快）
    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '武当山长');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    // 空闲面板「开始回归计时」主按钮（与标题区分，取按钮 key）
    await tester.tap(find.widgetWithText(InkWell, '开始回归计时').last);
    await tester.pumpAndSettle();

    // 倒计时面板特征
    expect(find.text('距回归任务开启还剩'), findsOneWidget);
    expect(find.text('天'), findsOneWidget);
    expect(find.text('时'), findsOneWidget);
    expect(find.text('分'), findsOneWidget);
    expect(find.text('秒'), findsOneWidget);
    expect(find.textContaining('周期进度'), findsOneWidget);
    expect(find.textContaining('请勿登录'), findsOneWidget);
    expect(find.text('放弃本轮计时'), findsOneWidget);
  });

  testWidgets('删除账号：两次点击确认后移除', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('添加账号'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '丐帮帮主');
    await tester.tap(find.text('保存账号'));
    await tester.pumpAndSettle();

    expect(find.text('丐帮帮主'), findsWidgets);

    // 点删除（第一次 arm → 显示“确认?”），再点即真删除。
    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    await tester.tap(find.byTooltip('确认删除？'));
    await tester.pumpAndSettle();

    expect(find.text('丐帮帮主'), findsNothing);
    expect(find.textContaining('暂无账号'), findsOneWidget);

    // 消化删除确认的 2.6s 复位 Timer，避免 dispose 时仍 pending。
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
