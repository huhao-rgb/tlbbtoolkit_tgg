import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/app/app.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';

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

  testWidgets('应用可以构建并展示首页', (tester) async {
    await pumpApp(tester);

    expect(find.text('工具箱'), findsOneWidget);
    // 本地模拟数据源会展示 4 个条目。
    expect(find.text('天龙助手'), findsOneWidget);
  });

  testWidgets('从首页可跳转到设置页', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('外观'), findsOneWidget);
    expect(find.text('通知提醒'), findsOneWidget);
  });

  testWidgets('切换深色模式会持久化到设置', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_settings');
    expect(raw, contains('dark'));
  });
}
