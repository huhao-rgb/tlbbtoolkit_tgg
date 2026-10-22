import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiangongge_installer/src/app.dart';
import 'package:tiangongge_installer/src/engine/install_engine.dart';
import 'package:tiangongge_installer/src/engine/shell_integration.dart';
import 'package:tiangongge_installer/src/flow.dart';

Future<void> setSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(960, 672);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget buildApp({bool uninstall = false}) {
  const shell = NoopShellIntegration();
  final controller = InstallerController(
    engine: DemoInstallEngine(shell),
    shell: shell,
    version: '1.13.0',
    startUninstall: uninstall,
    diskReader: (_) async => null,
  );
  return InstallerApp(controller: controller, windowControlsEnabled: false);
}

void main() {
  testWidgets('安装向导：欢迎 → 协议 → 位置 → 组件 → 进度 → 完成', (tester) async {
    await setSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('天 工 阁'), findsOneWidget);
    expect(find.text('天工阁 安装程序'), findsOneWidget);

    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();
    expect(find.text('用户许可协议'), findsOneWidget);

    // 未勾选协议时按钮禁用，点击不会前进
    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();
    expect(find.text('用户许可协议'), findsOneWidget);

    await tester.tap(find.text('我已阅读并同意上述协议条款'));
    await tester.pump();
    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();
    expect(find.text('选择安装位置'), findsOneWidget);

    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();
    expect(find.text('选择附加组件'), findsOneWidget);

    await tester.tap(find.text('安装'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('正在解压程序文件…'), findsOneWidget);

    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('安装完成'), findsOneWidget);
    expect(find.text('工具已备，山河可期'), findsOneWidget);
  });

  testWidgets('卸载向导：确认 → 进度 → 完成', (tester) async {
    await setSurface(tester);
    await tester.pumpWidget(buildApp(uninstall: true));
    await tester.pumpAndSettle();

    expect(find.text('确定要卸载 天工阁 吗？'), findsOneWidget);
    expect(find.text('天工阁 卸载程序'), findsOneWidget);

    await tester.tap(find.text('卸载'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('正在移除程序文件…'), findsOneWidget);

    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('卸载完成'), findsOneWidget);
    expect(find.text('天下无不散之筵席，江湖再见'), findsOneWidget);
  });

  testWidgets('组件开关会同步到安装请求状态', (tester) async {
    await setSurface(tester);
    const shell = NoopShellIntegration();
    final controller = InstallerController(
      engine: DemoInstallEngine(shell),
      shell: shell,
      version: '1.13.0',
      diskReader: (_) async => null,
    );
    await tester.pumpWidget(
      InstallerApp(controller: controller, windowControlsEnabled: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我已阅读并同意上述协议条款'));
    await tester.pump();
    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步 →'));
    await tester.pumpAndSettle();

    expect(controller.desktopShortcut, isTrue);
    await tester.tap(find.text('桌面快捷方式'));
    await tester.pump();
    expect(controller.desktopShortcut, isFalse);

    expect(controller.autostart, isFalse);
    await tester.tap(find.text('开机自启动'));
    await tester.pump();
    expect(controller.autostart, isTrue);
  });
}
