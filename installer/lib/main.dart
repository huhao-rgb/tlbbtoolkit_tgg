import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiangongge_installer/src/app.dart';
import 'package:tiangongge_installer/src/engine/install_engine.dart';
import 'package:tiangongge_installer/src/engine/models.dart';
import 'package:tiangongge_installer/src/engine/shell_integration.dart';
import 'package:tiangongge_installer/src/flow.dart';

/// 由构建脚本注入：`--dart-define=APP_VERSION=1.13.0`。
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.1.2');

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final shell = createShellIntegration();
  final engine = await createInstallEngine(shell: shell);

  // 控制面板的 QuietUninstallString：不显示窗口，直接保留用户数据并清理安装目录。
  if (args.contains('--uninstall') && args.contains('--quiet')) {
    final installDir = InstallerController.detectInstalledDir();
    await engine
        .uninstall(UninstallRequest(installDir: installDir, keepUserData: true))
        .drain<void>();
    await shell.scheduleSelfDelete();
    exit(0);
  }

  final controller = InstallerController(
    engine: engine,
    shell: shell,
    version: appVersion,
    startUninstall: args.contains('--uninstall'),
  );

  await setUpWindow(title: controller.caption);
  runApp(InstallerApp(controller: controller));
}
