import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/app/app.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';

/// 信息条组件的 key（与 shell_navigation 中的 `_InfoBar` 对应）。
const _infoBarKey = Key('shell-info-bar');

/// 在信息条内查找指定标题。
Finder infoBarTitle(String title) => find.descendant(
      of: find.byKey(_infoBarKey),
      matching: find.text(title),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TlbbApp(),
      ),
    );
    // 等待 home 异步数据加载完成。
    await tester.pumpAndSettle();
  }

  /// 以桌面窗口尺寸（1440×900，逻辑像素）泵入应用。
  Future<void> pumpAppAsDesktop(WidgetTester tester) async {
    tester.view.physicalSize =
        const Size(1440, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await pumpApp(tester);
  }

  testWidgets('应用可以构建并展示首页（信息条显示路由名 + tabbar）', (tester) async {
    await pumpApp(tester);

    // 顶部公共信息条显示当前路由名（home 分支的 name）。
    expect(infoBarTitle('工具箱'), findsOneWidget);
    // 本地模拟数据源会展示 4 个条目。
    expect(find.text('天龙助手'), findsOneWidget);
    // 底部 tabbar 存在两个一级页面。
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('一级页面没有返回按钮', (tester) async {
    await pumpApp(tester);

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('tabbar 可切换一级页面（工具箱 → 设置）', (tester) async {
    await pumpApp(tester);

    // 点击底部 tab「设置」。
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    // 信息条标题切换为「设置」。
    expect(infoBarTitle('设置'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('通知提醒'), findsOneWidget);
    // 一级页面没有返回按钮。
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('进入二级页面后信息条出现返回按钮，点击可返回', (tester) async {
    await pumpApp(tester);

    // 点击首页条目进入二级详情页。
    await tester.tap(find.text('天龙助手'));
    await tester.pumpAndSettle();

    // 信息条标题变为「工具详情」，并出现返回按钮。
    expect(infoBarTitle('工具详情'), findsOneWidget);
    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);

    // 点击返回按钮，回到一级页面。
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(infoBarTitle('工具箱'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('天龙助手'), findsOneWidget);
  });

  testWidgets('切换深色模式会持久化到设置', (tester) async {
    await pumpApp(tester);

    // 通过底部 tabbar 切换到设置页。
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_settings');
    expect(raw, contains('dark'));
  });

  testWidgets('桌面布局：左侧 NavigationRail，无底部 tabbar', (tester) async {
    await pumpAppAsDesktop(tester);

    // 桌面布局：左侧 NavigationRail。
    expect(find.byType(NavigationRail), findsOneWidget);
    // 不再有底部 tabbar。
    expect(find.byType(NavigationBar), findsNothing);
    // 右侧信息条仍显示当前路由名。
    expect(infoBarTitle('工具箱'), findsOneWidget);
  });

  testWidgets('桌面布局：侧栏可切换一级页面，二级页面仍有返回按钮', (tester) async {
    await pumpAppAsDesktop(tester);

    // 通过左侧侧栏切换到设置。
    await tester.tap(find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text('设置'),
    ));
    await tester.pumpAndSettle();
    expect(infoBarTitle('设置'), findsOneWidget);

    // 切回工具箱，进入二级详情页。
    await tester.tap(find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text('工具箱'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('天龙助手'));
    await tester.pumpAndSettle();

    // 二级页面信息条出现返回按钮，点击可返回。
    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(infoBarTitle('工具箱'), findsOneWidget);
  });
}
