import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tiangongge_installer/src/design/effects.dart';
import 'package:tiangongge_installer/src/design/tokens.dart';
import 'package:tiangongge_installer/src/design/widgets.dart';
import 'package:tiangongge_installer/src/flow.dart';
import 'package:tiangongge_installer/src/screens/common.dart';
import 'package:tiangongge_installer/src/screens/install_screens.dart';
import 'package:tiangongge_installer/src/screens/uninstall_screens.dart';
import 'package:window_manager/window_manager.dart';

class InstallerApp extends StatelessWidget {
  const InstallerApp({
    required this.controller,
    this.windowControlsEnabled = true,
    super.key,
  });

  final InstallerController controller;
  final bool windowControlsEnabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '天工阁 安装程序',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: T.winBg,
        fontFamily: T.sansFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: T.gold,
          brightness: Brightness.dark,
        ),
      ),
      home: InstallerShell(
        controller: controller,
        windowControlsEnabled: windowControlsEnabled,
      ),
    );
  }
}

class InstallerShell extends StatefulWidget {
  const InstallerShell({
    required this.controller,
    required this.windowControlsEnabled,
    super.key,
  });

  final InstallerController controller;
  final bool windowControlsEnabled;

  @override
  State<InstallerShell> createState() => _InstallerShellState();
}

class _InstallerShellState extends State<InstallerShell> with WindowListener {
  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    if (widget.windowControlsEnabled) windowManager.addListener(this);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    if (widget.windowControlsEnabled) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_handleClose());
  }

  Future<void> _handleClose() async {
    final controller = widget.controller;
    if (controller.busy) {
      _showToast(
        '正在${controller.kind == WizardKind.install ? '安装' : '卸载'}，请稍候…',
      );
      return;
    }
    if (controller.isFinishStep) await controller.finish();
    await _closeWindow();
  }

  Future<void> _closeWindow() async {
    if (!widget.windowControlsEnabled) return;
    await windowManager.destroy();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: T.winBg,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Stack(
          children: [
            Column(
              children: [
                DragToMoveArea(
                  child: WindowTitleBar(
                    caption: controller.caption,
                    onMinimize: widget.windowControlsEnabled
                        ? () => windowManager.minimize()
                        : () {},
                    onMaximize: widget.windowControlsEnabled
                        ? () async {
                            if (await windowManager.isMaximized()) {
                              await windowManager.unmaximize();
                            } else {
                              await windowManager.maximize();
                            }
                          }
                        : () {},
                    onClose: _handleClose,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Sidebar(
                        version: 'v${controller.version}',
                        steps: controller.steps,
                        currentIndex: controller.index,
                        footTip: _sideTip(controller),
                        extra: kDebugMode
                            ? GestureDetector(
                                onTap: controller.switchFlowForDebug,
                                child: Text(
                                  controller.kind == WizardKind.install
                                      ? '预览卸载向导'
                                      : '预览安装向导',
                                  style: T.sans(
                                    size: 10.5,
                                    color: T.gold.withValues(alpha: 0.9),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Container(
                          color: T.winBg,
                          padding: const EdgeInsets.fromLTRB(42, 38, 42, 26),
                          child: FadeSlideSwitcher(
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${controller.kind.name}-${controller.index}',
                              ),
                              child: _page(controller),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _footer(controller),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _toast == null ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE61A1A20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: T.goldBorder),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 24),
                        ],
                      ),
                      child: Text(
                        _toast ?? '',
                        style: T.sans(size: 12, color: T.t1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideTip(InstallerController controller) {
    if (controller.kind == WizardKind.uninstall) {
      return LogoSidebarTip(
        leading: '本程序安装于 ',
        highlight: controller.installDir,
        trailing: '',
      );
    }
    return LogoSidebarTip(
      leading: '安装包大小 ',
      highlight: formatBytes(controller.engine.payload.packageBytes),
      trailing: ' · 建议 Windows 10 / 11 64 位',
      extra: controller.engine.isDemo ? '演示模式：未找到 payload.zip' : null,
    );
  }

  Widget _page(InstallerController controller) {
    if (controller.kind == WizardKind.install) {
      return switch (controller.index) {
        0 => WelcomePage(controller: controller),
        1 => LicenseAgreementPage(controller: controller),
        2 => LocationPage(controller: controller),
        3 => ComponentsPage(controller: controller),
        4 => InstallProgressPage(controller: controller),
        _ => InstallFinishPage(controller: controller),
      };
    }
    return switch (controller.index) {
      0 => UninstallConfirmPage(controller: controller),
      1 => UninstallProgressPage(controller: controller),
      _ => UninstallFinishPage(controller: controller),
    };
  }

  Widget _footer(InstallerController controller) {
    final children = <Widget>[];
    final install = controller.kind == WizardKind.install;

    if (install && controller.index == 1) {
      children.add(
        CheckLine(
          checked: controller.agreed,
          label: '我接受《天工阁用户许可协议》中的条款',
          onTap: controller.toggleAgreed,
          fontSize: 11.5,
          gap: 9,
        ),
      );
    }

    children.add(const Spacer());

    if (controller.error != null && controller.isProgressStep) {
      children
        ..add(AppButton(label: '关闭', onPressed: _closeWindow))
        ..add(const SizedBox(width: 12))
        ..add(
          AppButton(
            label: '重试',
            kind: AppButtonKind.primary,
            onPressed: () => controller.retry(),
          ),
        );
    } else if (install) {
      switch (controller.index) {
        case 0:
          children
            ..add(AppButton(label: '取消', onPressed: _closeWindow))
            ..add(const SizedBox(width: 12))
            ..add(
              AppButton(
                label: '下一步 →',
                kind: AppButtonKind.primary,
                onPressed: controller.next,
              ),
            );
        case 1:
          children
            ..add(AppButton(label: '← 上一步', onPressed: controller.back))
            ..add(const SizedBox(width: 12))
            ..add(
              AppButton(
                label: '下一步 →',
                kind: AppButtonKind.primary,
                onPressed: controller.canGoNext ? controller.next : null,
              ),
            );
        case 2:
          children
            ..add(AppButton(label: '← 上一步', onPressed: controller.back))
            ..add(const SizedBox(width: 12))
            ..add(
              AppButton(
                label: '下一步 →',
                kind: AppButtonKind.primary,
                onPressed: controller.canGoNext ? controller.next : null,
              ),
            );
        case 3:
          children
            ..add(AppButton(label: '← 上一步', onPressed: controller.back))
            ..add(const SizedBox(width: 12))
            ..add(
              AppButton(
                label: '安装',
                kind: AppButtonKind.primary,
                onPressed: controller.next,
              ),
            );
        case 4:
          children.add(const AppButton(label: '正在安装，请稍候…', onPressed: null));
        case 5:
          children.add(
            AppButton(
              label: '完成',
              kind: AppButtonKind.primary,
              onPressed: () async {
                await controller.finish();
                await _closeWindow();
              },
            ),
          );
      }
    } else {
      switch (controller.index) {
        case 0:
          children
            ..add(AppButton(label: '取消', onPressed: _closeWindow))
            ..add(const SizedBox(width: 12))
            ..add(
              AppButton(
                label: '卸载',
                kind: AppButtonKind.danger,
                onPressed: controller.next,
              ),
            );
        case 1:
          children.add(const AppButton(label: '正在卸载，请稍候…', onPressed: null));
        case 2:
          children.add(
            AppButton(
              label: '关闭',
              kind: AppButtonKind.primary,
              onPressed: () async {
                await controller.finish();
                await _closeWindow();
              },
            ),
          );
      }
    }

    return FooterBar(children: children);
  }
}

/// 供 main() 调用：无边框窗口 + 固定初始尺寸。
Future<void> setUpWindow({required String title}) async {
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

  await windowManager.ensureInitialized();

  // 小屏 / 高缩放下按工作区收缩，避免窗口超出屏幕。
  var size = T.windowSize;
  try {
    final display = await screenRetriever.getPrimaryDisplay();
    final visible = display.visibleSize ?? display.size;
    size = Size(
      math.min(size.width, math.max(760, visible.width - 32)),
      math.min(size.height, math.max(540, visible.height - 32)),
    );
  } on Object {
    // 拿不到屏幕信息时保持设计稿尺寸。
  }

  final options = WindowOptions(
    size: size,
    minimumSize: Size(
      math.min(T.minWindowSize.width, size.width),
      math.min(T.minWindowSize.height, size.height),
    ),
    center: true,
    title: '天工阁 安装程序',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPreventClose(true);
    if (Platform.isWindows || Platform.isLinux) {
      await windowManager.setAsFrameless();
    }
    if (Platform.isMacOS) await windowManager.setHasShadow(true);
    await windowManager.setTitle(title);
    await windowManager.show();
    await windowManager.focus();
  });
}
