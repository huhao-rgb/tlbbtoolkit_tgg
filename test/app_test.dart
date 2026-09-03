import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/app/app.dart';
import 'package:tlbbtoolkit/app/shell_navigation/widgets/desktop_sidebar.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';

/// 信息条组件的 key（与 app_info_bar 中的 `AppInfoBar` 对应）。
const _infoBarKey = Key('shell-info-bar');
const _backButtonKey = Key('shell-back-button');
const _chipsKey = Key('home-filter-chips');
const _settingsBackKey = Key('settings-back-button');

/// 在信息条内查找指定标题。
Finder infoBarTitle(String title) => find.descendant(
      of: find.byKey(_infoBarKey),
      matching: find.text(title),
    );

/// 移动端底部 NavigationBar 中的 tab。
Finder bottomTab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

/// 桌面侧栏中的导航项。
Finder sidebarItem(String label) => find.descendant(
      of: find.byType(DesktopSidebar),
      matching: find.text(label),
    );

/// 首页分类筛选 chips 中的项。
Finder homeChip(String label) => find.descendant(
      of: find.byKey(_chipsKey),
      matching: find.text(label),
    );

/// 滚动到目标并令其居于视口中央（默认 ensureVisible 会贴顶，
/// 在悬浮毛玻璃顶栏下会被玻璃遮挡）。
Future<void> revealCenter(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pump();
}

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
    await tester.pumpAndSettle();
  }

  /// 以桌面窗口尺寸（1440×1024，逻辑像素）泵入应用。
  Future<void> pumpAppAsDesktop(WidgetTester tester) async {
    tester.view.physicalSize =
        const Size(1440, 1024) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await pumpApp(tester);
  }

  // ---------- 移动端 ----------

  testWidgets('移动端首页：Hero + 信息条 + 4 段底部 tab', (tester) async {
    await pumpApp(tester);

    expect(infoBarTitle('首页'), findsOneWidget);
    expect(find.text('天工阁'), findsOneWidget);
    // 底部 tab 四段：首页 / 宝宝 / 兽灵·兽魂 / 职业。
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(bottomTab('首页'), findsOneWidget);
    expect(bottomTab('宝宝'), findsOneWidget);
    expect(bottomTab('兽灵·兽魂'), findsOneWidget);
    expect(bottomTab('职业'), findsOneWidget);
    // 工具网格入口存在。
    expect(find.text('宝宝资质计算'), findsOneWidget);
    // 一级页面无返回按钮。
    expect(find.byKey(_backButtonKey), findsNothing);
  });

  testWidgets('移动端底部 tab 可切到分类 hub（宝宝）', (tester) async {
    await pumpApp(tester);

    await tester.tap(bottomTab('宝宝'));
    await tester.pumpAndSettle();

    expect(infoBarTitle('宝宝工具'), findsOneWidget);
    expect(find.text('宝宝套装图鉴'), findsOneWidget);
    // hub 是一级页面：无返回按钮。
    expect(find.byKey(_backButtonKey), findsNothing);
  });

  testWidgets('hub 内进入工具二级页，返回回到该 hub', (tester) async {
    await pumpApp(tester);

    await tester.tap(bottomTab('宝宝'));
    await tester.pumpAndSettle();

    await revealCenter(tester, find.text('宝宝资质计算'));
    await tester.tap(find.text('宝宝资质计算'));
    await tester.pumpAndSettle();

    expect(infoBarTitle('宝宝资质计算'), findsOneWidget);
    expect(find.byKey(_backButtonKey), findsOneWidget);

    // 返回 → 回到「宝宝工具」hub（当前分支根）。
    await tester.tap(find.byKey(_backButtonKey));
    await tester.pumpAndSettle();
    expect(infoBarTitle('宝宝工具'), findsOneWidget);
  });

  testWidgets('首页网格直达工具（跨分支），返回其 hub，再回首页', (tester) async {
    await pumpApp(tester);

    await revealCenter(tester, find.text('兽魂查询'));
    await tester.tap(find.text('兽魂查询'));
    await tester.pumpAndSettle();

    expect(infoBarTitle('兽魂查询'), findsOneWidget);
    expect(find.byKey(_backButtonKey), findsOneWidget);

    // 返回 → 兽灵·兽魂 hub。
    await tester.tap(find.byKey(_backButtonKey));
    await tester.pumpAndSettle();
    expect(infoBarTitle('兽灵 · 兽魂'), findsOneWidget);

    // 底部「首页」tab 回到首页。
    await tester.tap(bottomTab('首页'));
    await tester.pumpAndSettle();
    expect(infoBarTitle('首页'), findsOneWidget);
  });

  testWidgets('工具页面包屑可返回所属 hub', (tester) async {
    await pumpApp(tester);

    await revealCenter(tester, find.text('职业加点计算器'));
    await tester.tap(find.text('职业加点计算器'));
    await tester.pumpAndSettle();
    expect(infoBarTitle('职业加点计算器'), findsOneWidget);

    // 点击页头面包屑首段「职业」→ 职业中心 hub。
    await revealCenter(tester, find.byKey(const Key('crumb-职业')));
    await tester.tap(find.byKey(const Key('crumb-职业')));
    await tester.pumpAndSettle();

    expect(infoBarTitle('职业中心'), findsOneWidget);
    expect(find.text('职业神器'), findsOneWidget);
  });

  testWidgets('首页分类筛选（chips）', (tester) async {
    await pumpApp(tester);

    // 默认显示全部。
    expect(find.text('宝宝资质计算'), findsOneWidget);
    expect(find.text('职业加点计算器'), findsOneWidget);

    await revealCenter(tester, homeChip('职业'));
    await tester.tap(homeChip('职业'));
    await tester.pumpAndSettle();

    expect(find.text('职业加点计算器'), findsOneWidget);
    expect(find.text('宝宝资质计算'), findsNothing);
  });

  testWidgets('首页搜索按关键词过滤', (tester) async {
    await pumpApp(tester);

    await revealCenter(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '兽魂');
    // 输入聚焦会启动光标闪烁计时，用固定时长 pump 而非 pumpAndSettle。
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('兽魂查询'), findsOneWidget);
    expect(find.text('职业加点计算器'), findsNothing);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('设置：顶栏齿轮进入独立设置页，可返回', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('外观'), findsOneWidget);
    expect(find.byKey(_settingsBackKey), findsOneWidget);

    await tester.tap(find.byKey(_settingsBackKey));
    await tester.pumpAndSettle();
    expect(infoBarTitle('首页'), findsOneWidget);
  });

  testWidgets('顶栏主题快捷切换会持久化', (tester) async {
    await pumpApp(tester);

    // 默认（system=浅色）显示“切到深色”图标。
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_settings');
    expect(raw, contains('dark'));
  });

  // ---------- 桌面端 ----------

  testWidgets('桌面布局：236 侧栏（品牌+分组工具导航），无底部 tab', (tester) async {
    await pumpAppAsDesktop(tester);

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(sidebarItem('首页'), findsOneWidget);
    expect(sidebarItem('宝宝资质计算'), findsOneWidget);
    expect(infoBarTitle('首页'), findsOneWidget);
  });

  testWidgets('桌面侧栏可直达工具并返回；首页项可回首页', (tester) async {
    await pumpAppAsDesktop(tester);

    await revealCenter(tester, sidebarItem('宝宝资质计算'));
    await tester.tap(sidebarItem('宝宝资质计算'));
    await tester.pumpAndSettle();

    expect(infoBarTitle('宝宝资质计算'), findsOneWidget);
    expect(find.byKey(_backButtonKey), findsOneWidget);

    // 侧栏「首页」回到首页。
    await tester.tap(sidebarItem('首页'));
    await tester.pumpAndSettle();
    expect(infoBarTitle('首页'), findsOneWidget);
  });

  testWidgets('桌面侧栏分组完整列出 11 个工具', (tester) async {
    await pumpAppAsDesktop(tester);

    // 滚动到侧栏列表末尾，确认「职业加点计算器」等项存在。
    final sideList = find.descendant(
      of: find.byType(DesktopSidebar),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      sidebarItem('门派介绍'),
      120,
      scrollable: sideList.first,
    );
    expect(sidebarItem('门派介绍'), findsOneWidget);
    expect(sidebarItem('职业神器'), findsOneWidget);
  });
}
