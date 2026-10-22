import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:tiangongge_installer/src/engine/disk_space.dart';
import 'package:tiangongge_installer/src/engine/install_engine.dart';
import 'package:tiangongge_installer/src/engine/models.dart';
import 'package:tiangongge_installer/src/engine/paths.dart';
import 'package:tiangongge_installer/src/engine/process_guard.dart';
import 'package:tiangongge_installer/src/engine/shell_integration.dart';

enum WizardKind { install, uninstall }

/// 安装 / 卸载向导的唯一状态源（不依赖 Riverpod，安装器是独立小工程）。
class InstallerController extends ChangeNotifier {
  InstallerController({
    required this.engine,
    required this.shell,
    required this.version,
    bool startUninstall = false,
    Future<DiskSpace?> Function(String path)? diskReader,
    ProcessGuard? processGuard,
  }) : _diskReader = diskReader ?? readDiskSpace,
       _processGuard = processGuard ?? createProcessGuard(),
       kind = startUninstall ? WizardKind.uninstall : WizardKind.install,
       installDir = startUninstall
           ? detectInstalledDir()
           : AppPaths.defaultInstallDir {
    unawaited(_refreshDisk());
  }

  final InstallEngine engine;
  final ShellIntegration shell;
  final String version;
  final Future<DiskSpace?> Function(String path) _diskReader;
  final ProcessGuard _processGuard;

  WizardKind kind;
  int index = 0;

  bool agreed = false;
  String installDir;
  bool desktopShortcut = true;
  bool autostart = false;
  bool offlineData = true;
  bool runAfter = true;
  bool keepUserData = true;

  InstallProgress progress = InstallProgress.idle;
  bool busy = false;
  Object? error;
  DiskSpace? disk;

  /// 目标程序正在运行，等待用户确认关闭。
  bool blockedByRunningApp = false;
  void Function()? _afterClose;

  StreamSubscription<InstallProgress>? _subscription;
  bool _disposed = false;

  static const _installSteps = ['欢迎安装', '许可协议', '安装位置', '组件选择', '正在安装', '完成'];

  static const _uninstallSteps = ['确认卸载', '正在卸载', '完成'];

  List<String> get steps =>
      kind == WizardKind.install ? _installSteps : _uninstallSteps;

  int get stepCount => steps.length;

  String get caption => kind == WizardKind.install ? '天工阁 安装程序' : '天工阁 卸载程序';

  String get currentTitle => steps[index];

  bool get isLastStep => index == stepCount - 1;

  bool get isProgressStep =>
      (kind == WizardKind.install && index == 4) ||
      (kind == WizardKind.uninstall && index == 1);

  bool get isFinishStep => isLastStep;

  bool get canGoNext {
    if (kind == WizardKind.install) {
      return switch (index) {
        1 => agreed,
        2 => installDir.trim().isNotEmpty,
        _ => true,
      };
    }
    return true;
  }

  String get primaryLabel {
    if (kind == WizardKind.install) {
      return switch (index) {
        0 || 1 || 2 => '下一步 →',
        3 => '安装',
        5 => '完成',
        _ => '',
      };
    }
    return switch (index) {
      0 => '卸载',
      2 => '关闭',
      _ => '',
    };
  }

  static String detectInstalledDir() {
    final selfDir = AppPaths.selfDir;
    if (p.basename(selfDir) == AppPaths.uninstallerFolderName) {
      return p.dirname(selfDir);
    }
    return AppPaths.defaultInstallDir;
  }

  void next() {
    if (!canGoNext) return;
    if (kind == WizardKind.install) {
      switch (index) {
        case 0:
        case 1:
        case 2:
          _goTo(index + 1);
        case 3:
          unawaited(
            _guardThen(() {
              _goTo(4);
              unawaited(_startInstall());
            }),
          );
      }
    } else if (index == 0) {
      unawaited(
        _guardThen(() {
          _goTo(1);
          unawaited(_startUninstall());
        }),
      );
    }
  }

  Future<void> _guardThen(void Function() action) async {
    if (await _processGuard.isRunning(AppPaths.appExeName)) {
      _afterClose = action;
      blockedByRunningApp = true;
      _notify();
      return;
    }
    action();
  }

  Future<void> closeRunningApp() async {
    await _processGuard.closeAll(AppPaths.appExeName);
    final action = _afterClose;
    _afterClose = null;
    blockedByRunningApp = false;
    _notify();
    action?.call();
  }

  void dismissRunningApp() {
    _afterClose = null;
    blockedByRunningApp = false;
    _notify();
  }

  void back() {
    if (index > 0 && !isProgressStep) _goTo(index - 1);
  }

  void toggleAgreed() {
    agreed = !agreed;
    _notify();
  }

  void toggleDesktopShortcut() {
    desktopShortcut = !desktopShortcut;
    _notify();
  }

  void toggleAutostart() {
    autostart = !autostart;
    _notify();
  }

  void toggleOfflineData() {
    offlineData = !offlineData;
    _notify();
  }

  void toggleRunAfter() {
    runAfter = !runAfter;
    _notify();
  }

  void toggleKeepUserData() {
    keepUserData = !keepUserData;
    _notify();
  }

  void setInstallDir(String value) {
    if (value == installDir) return;
    installDir = value;
    _notify();
    unawaited(_refreshDisk());
  }

  void browseInstallDir(String value) {
    setInstallDir(value);
  }

  Future<void> _refreshDisk() async {
    final result = await _diskReader(installDir);
    if (_disposed) return;
    disk = result;
    _notify();
  }

  Set<InstallComponent> get components => {
    if (desktopShortcut) InstallComponent.desktopShortcut,
    if (autostart) InstallComponent.autostart,
    if (offlineData) InstallComponent.offlineData,
  };

  Future<void> _startInstall() async {
    busy = true;
    error = null;
    progress = const InstallProgress(phase: '正在准备安装…');
    _notify();

    _subscription?.cancel();
    _subscription = engine
        .install(
          InstallRequest(
            installDir: installDir,
            components: components,
            version: version,
            runAfter: runAfter,
          ),
        )
        .listen(
          _onProgress,
          onDone: _onStreamDone,
          onError: (Object e) {
            error = e;
            busy = false;
            _notify();
          },
        );
  }

  Future<void> _startUninstall() async {
    busy = true;
    error = null;
    progress = const InstallProgress(phase: '正在准备卸载…');
    _notify();

    _subscription?.cancel();
    _subscription = engine
        .uninstall(
          UninstallRequest(installDir: installDir, keepUserData: keepUserData),
        )
        .listen(
          _onProgress,
          onDone: _onStreamDone,
          onError: (Object e) {
            error = e;
            busy = false;
            _notify();
          },
        );
  }

  void _onProgress(InstallProgress value) {
    progress = value;
    if (value.error != null) error = value.error;
    if (value.done && value.error == null) {
      busy = false;
      index = kind == WizardKind.install ? 5 : 2;
    }
    _notify();
  }

  void _onStreamDone() {
    if (busy) {
      busy = false;
      if (error == null) {
        index = kind == WizardKind.install ? 5 : 2;
      }
    }
    _notify();
  }

  Future<void> retry() async {
    error = null;
    if (kind == WizardKind.install) {
      await _guardThen(() => unawaited(_startInstall()));
    } else {
      await _guardThen(() => unawaited(_startUninstall()));
    }
  }

  Future<void> finish() async {
    if (error != null) return;
    if (kind == WizardKind.uninstall) {
      // 卸载器目录不可能在运行时删掉，交给退出后的后台清理。
      await shell.scheduleSelfDelete();
      return;
    }
    final exe = AppPaths.installedExe(installDir);
    final link = shell.desktopShortcutLink();
    try {
      // 完成页上的勾选在离开前生效：勾选则补齐快捷方式，取消则删掉。
      if (desktopShortcut) {
        if (!File(link).existsSync()) {
          await shell.createShortcut(
            linkPath: link,
            target: exe,
            workingDirectory: installDir,
            iconPath: exe,
          );
        }
      } else {
        await shell.deleteShortcut(link);
      }
      if (runAfter) await shell.launch(exe);
    } on Object {
      // 启动 / 快捷方式失败都不应阻塞“完成”按钮。
    }
  }

  void switchFlowForDebug() {
    kind = kind == WizardKind.install
        ? WizardKind.uninstall
        : WizardKind.install;
    index = 0;
    agreed = false;
    error = null;
    busy = false;
    progress = InstallProgress.idle;
    if (kind == WizardKind.uninstall) installDir = detectInstalledDir();
    _notify();
  }

  void _goTo(int next) {
    index = next;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
