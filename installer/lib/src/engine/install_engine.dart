import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:tiangongge_installer/src/engine/models.dart';
import 'package:tiangongge_installer/src/engine/paths.dart';
import 'package:tiangongge_installer/src/engine/shell_integration.dart';

abstract class InstallEngine {
  PayloadInfo get payload;

  bool get isDemo;

  Stream<InstallProgress> install(InstallRequest request);

  Stream<InstallProgress> uninstall(UninstallRequest request);

  InstallManifest? readManifest(String installDir);
}

/// 构建脚本没有放入 payload.zip 时，用演示引擎跑通界面（Release 构建也会走这里，
/// 因此侧栏会明确标注“演示模式”）。
Future<InstallEngine> createInstallEngine({
  ShellIntegration? shell,
  String? payloadPath,
}) async {
  final integration = shell ?? createShellIntegration();
  final resolved = payloadPath ?? AppPaths.resolvePayload();
  if (resolved == null || !File(resolved).existsSync()) {
    // 非调试构建缺少 payload 时必须明确报错，避免“假安装成功”。
    if (!kDebugMode) return MissingPayloadEngine();
    return DemoInstallEngine(integration);
  }
  final info = await _describePayload(resolved);
  return ArchiveInstallEngine(
    payloadPath: resolved,
    payload: info,
    shell: integration,
  );
}

Future<PayloadInfo> _describePayload(String path) async {
  final packageBytes = File(path).lengthSync();
  var required = packageBytes;
  try {
    final input = InputFileStream(path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      required = archive.files
          .where((file) => file.isFile)
          .fold<int>(0, (sum, file) => sum + file.size);
    } finally {
      input.closeSync();
    }
  } on Object {
    // 压缩包损坏时保留包体积，安装阶段会给出明确错误。
  }
  return PayloadInfo(
    packageBytes: packageBytes,
    requiredBytes: (required * 1.08).round() + 8 * 1024 * 1024,
    isDemo: false,
  );
}

class ArchiveInstallEngine implements InstallEngine {
  ArchiveInstallEngine({
    required this.payloadPath,
    required this.payload,
    required this.shell,
    this.dataDirOverride,
    this.provisionUninstaller = true,
  });

  final String payloadPath;
  final ShellIntegration shell;
  final String? dataDirOverride;
  final bool provisionUninstaller;

  String get _dataDir => dataDirOverride ?? AppPaths.dataDir;

  @override
  final PayloadInfo payload;

  @override
  bool get isDemo => false;

  @override
  InstallManifest? readManifest(String installDir) {
    final file = File(AppPaths.manifestPath(installDir));
    if (!file.existsSync()) return null;
    return InstallManifest.decode(file.readAsStringSync());
  }

  @override
  Stream<InstallProgress> install(InstallRequest request) async* {
    final log = <String>[];
    final installDir = request.installDir;
    final stopwatch = Stopwatch()..start();
    var lastSampleMs = 0;
    var lastSampleBytes = 0;
    var speed = 0.0;

    try {
      Directory(installDir).createSync(recursive: true);
      log.add('准备安装到 $installDir');
      yield InstallProgress(phase: '正在准备安装…', log: List.of(log));

      final input = InputFileStream(payloadPath);
      Archive? archive;
      try {
        archive = ZipDecoder().decodeStream(input);
        final files = archive.files
            .where((file) => file.isFile && !_isUnsafe(file.name))
            .toList();
        final totalBytes = files.fold<int>(0, (sum, file) => sum + file.size);
        var writtenBytes = 0;

        for (final file in files) {
          final name = file.name.replaceAll('\\', '/');
          if (!request.components.contains(InstallComponent.offlineData) &&
              name.startsWith('offline/')) {
            continue;
          }

          final target = p.joinAll([installDir, ...name.split('/')]);
          Directory(p.dirname(target)).createSync(recursive: true);
          final output = OutputFileStream(target);
          try {
            file.writeContent(output);
          } finally {
            output.closeSync();
          }

          writtenBytes += file.size;
          log.add('解压 · $name');
          _trimLog(log);

          final elapsedMs = stopwatch.elapsedMilliseconds;
          if (elapsedMs - lastSampleMs >= 120) {
            final deltaBytes = writtenBytes - lastSampleBytes;
            final deltaMs = elapsedMs - lastSampleMs;
            if (deltaMs > 0) {
              final instant = deltaBytes * 1000 / deltaMs;
              speed = speed == 0 ? instant : speed * 0.7 + instant * 0.3;
            }
            lastSampleMs = elapsedMs;
            lastSampleBytes = writtenBytes;

            final remaining = totalBytes - writtenBytes;
            yield InstallProgress(
              phase: '正在解压程序文件…',
              fraction: totalBytes == 0 ? 0 : writtenBytes / totalBytes * 0.9,
              currentFile: name,
              bytesPerSecond: speed,
              eta: speed <= 0
                  ? null
                  : Duration(seconds: (remaining / speed).ceil()),
              log: List.of(log),
            );
          }
        }
      } finally {
        input.closeSync();
      }

      yield InstallProgress(
        phase: '正在创建快捷方式…',
        fraction: 0.92,
        bytesPerSecond: speed,
        log: List.of(log),
      );

      final exe = AppPaths.installedExe(installDir);
      await shell.createShortcut(
        linkPath: shell.startMenuShortcutLink(),
        target: exe,
        workingDirectory: installDir,
        iconPath: exe,
      );
      log.add('创建 · 开始菜单快捷方式');

      if (request.components.contains(InstallComponent.desktopShortcut)) {
        await shell.createShortcut(
          linkPath: shell.desktopShortcutLink(),
          target: exe,
          workingDirectory: installDir,
          iconPath: exe,
        );
        log.add('创建 · 桌面快捷方式');
      }

      await shell.setAutostart(
        enabled: request.components.contains(InstallComponent.autostart),
        exePath: exe,
      );
      log.add('写入 · 开机自启动设置');

      yield InstallProgress(
        phase: '正在部署卸载程序…',
        fraction: 0.94,
        bytesPerSecond: speed,
        log: List.of(log),
      );
      final uninstallerBytes = provisionUninstaller
          ? await _provisionUninstaller(installDir)
          : 0;

      final installedBytes =
          (await _directorySize(
            installDir,
            skip: AppPaths.uninstallerDir(installDir),
          )) +
          uninstallerBytes;
      final manifest = InstallManifest(
        version: request.version,
        installDir: installDir,
        dataDir: _dataDir,
        components: request.components.map((c) => c.name).toList(),
        installedAt: DateTime.now().toIso8601String(),
        installedBytes: installedBytes,
      );
      File(AppPaths.manifestPath(installDir))
          .writeAsStringSync(manifest.encode());
      log.add('写入 · 安装清单');

      await shell.writeUninstallEntry(
        manifest: manifest,
        uninstallerPath: AppPaths.uninstallerExe(installDir),
        estimatedBytes: installedBytes,
      );
      log.add('写入 · 系统卸载项');

      Directory(_dataDir).createSync(recursive: true);
      if (request.components.contains(InstallComponent.offlineData)) {
        log.add('完成 · 行情离线数据包');
      }

      yield InstallProgress(
        phase: '安装完成',
        fraction: 1,
        bytesPerSecond: speed,
        eta: Duration.zero,
        log: List.of(log),
        done: true,
      );
    } on Object catch (error, stack) {
      log.add('错误 · $error');
      yield InstallProgress(
        phase: '安装失败',
        fraction: 0,
        log: List.of(log),
        done: true,
        error: error,
      );
      assert(() {
        // ignore: avoid_print
        print(stack);
        return true;
      }());
    }
  }

  @override
  Stream<InstallProgress> uninstall(UninstallRequest request) async* {
    final log = <String>[];
    final installDir = request.installDir;
    final uninstallerDir = AppPaths.uninstallerDir(installDir);

    try {
      final manifest = readManifest(installDir);
      final files = <File>[];
      final dir = Directory(installDir);
      if (dir.existsSync()) {
        for (final entity in dir.listSync(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File && !p.isWithin(uninstallerDir, entity.path)) {
            files.add(entity);
          }
        }
      }

      final totalBytes = files.fold<int>(
        0,
        (sum, file) => sum + file.lengthSync(),
      );
      var removedBytes = 0;

      for (final file in files) {
        final relative = p.relative(file.path, from: installDir);
        try {
          removedBytes += file.lengthSync();
          file.deleteSync();
          log.add('移除 · $relative');
          _trimLog(log);
        } on FileSystemException {
          log.add('跳过 · $relative（占用中）');
        }
        yield InstallProgress(
          phase: '正在移除程序文件…',
          fraction: totalBytes == 0 ? 0.5 : removedBytes / totalBytes * 0.8,
          currentFile: relative,
          log: List.of(log),
        );
      }

      _deleteEmptyDirs(installDir, skip: uninstallerDir);

      yield InstallProgress(
        phase: '正在清理快捷方式与注册表…',
        fraction: 0.88,
        log: List.of(log),
      );
      await shell.deleteShortcut(shell.desktopShortcutLink());
      await shell.deleteShortcut(shell.startMenuShortcutLink());
      await shell.setAutostart(
        enabled: false,
        exePath: AppPaths.installedExe(installDir),
      );
      await shell.removeUninstallEntry();
      log.add('清理 · 快捷方式、自启动、卸载注册表项');

      if (!request.keepUserData) {
        final data = Directory(manifest?.dataDir ?? _dataDir);
        if (data.existsSync()) {
          data.deleteSync(recursive: true);
          log.add('清空 · ${data.path}');
        }
      } else {
        log.add('保留 · ${manifest?.dataDir ?? AppPaths.dataDir}');
      }

      yield InstallProgress(
        phase: '卸载完成',
        fraction: 1,
        eta: Duration.zero,
        log: List.of(log),
        done: true,
      );
    } on Object catch (error) {
      log.add('错误 · $error');
      yield InstallProgress(
        phase: '卸载失败',
        fraction: 0,
        log: List.of(log),
        done: true,
        error: error,
      );
    }
  }

  bool _isUnsafe(String name) {
    final normalized = name.replaceAll('\\', '/');
    return normalized.split('/').contains('..') || normalized.startsWith('/');
  }

  void _trimLog(List<String> log) {
    if (log.length > 60) log.removeRange(0, log.length - 60);
  }

  /// 把安装器自身运行时复制到 <安装目录>\.uninstaller，供控制面板调用。
  Future<int> _provisionUninstaller(String installDir) async {
    final source = Directory(AppPaths.selfDir);
    final target = Directory(AppPaths.uninstallerDir(installDir));
    if (p.equals(source.path, target.path) ||
        p.isWithin(target.path, source.path)) {
      return 0;
    }

    var copied = 0;
    for (final entity in source.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: source.path);
      if (relative.split(p.separator).contains('payload') ||
          p.basename(relative) == 'payload.zip') {
        continue;
      }
      final destination = File(p.join(target.path, relative));
      destination.parent.createSync(recursive: true);
      entity.copySync(destination.path);
      copied += entity.lengthSync();
    }
    return copied;
  }

  Future<int> _directorySize(String path, {String? skip}) async {
    final dir = Directory(path);
    if (!dir.existsSync()) return 0;
    var total = 0;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File && (skip == null || !p.isWithin(skip, entity.path))) {
        total += entity.lengthSync();
      }
    }
    return total;
  }

  void _deleteEmptyDirs(String root, {required String skip}) {
    final dir = Directory(root);
    if (!dir.existsSync()) return;
    final dirs =
        dir
            .listSync(recursive: true, followLinks: false)
            .whereType<Directory>()
            .where((d) => !p.isWithin(skip, d.path) && !p.equals(d.path, skip))
            .toList()
          ..sort((a, b) => b.path.length.compareTo(a.path.length));
    for (final d in dirs) {
      try {
        if (d.listSync().isEmpty) d.deleteSync();
      } on FileSystemException {
        // 被占用就留给系统清理。
      }
    }
  }
}

/// 没有 payload.zip 时的演示实现：界面、日志、速度曲线与真实安装一致。
class DemoInstallEngine implements InstallEngine {
  DemoInstallEngine(this.shell);

  final ShellIntegration shell;

  @override
  PayloadInfo get payload => const PayloadInfo(
    packageBytes: 286 * 1024 * 1024,
    requiredBytes: 320 * 1024 * 1024,
    isDemo: true,
  );

  @override
  bool get isDemo => true;

  @override
  InstallManifest? readManifest(String installDir) => null;

  static const _installFiles = [
    'assets/core.pkg',
    'assets/pet-soul.pkg',
    'assets/beast-index.pkg',
    'assets/market-90d.db',
    'locale/zh-CN.lang',
    'icons/theme-gold.ico',
    '完成写入注册表项',
    '清理临时文件',
  ];

  @override
  Stream<InstallProgress> install(InstallRequest request) async* {
    final log = <String>[];
    const total = 24;
    for (var i = 1; i <= total; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      final fileIndex = ((i - 1) * _installFiles.length ~/ total).clamp(
        0,
        _installFiles.length - 1,
      );
      final file = _installFiles[fileIndex];
      if (log.isEmpty || log.last != '解压 · $file') {
        log.add('解压 · $file');
      }
      final fraction = i / total;
      final speed = 8 * 1024 * 1024 + (i % 5) * 1.6 * 1024 * 1024;
      yield InstallProgress(
        phase: i < total * 0.85 ? '正在解压程序文件…' : '正在写入注册表项…',
        fraction: fraction,
        currentFile: file,
        bytesPerSecond: speed,
        eta: Duration(seconds: ((total - i) * 0.09).ceil()),
        log: List.of(log),
      );
    }
    yield InstallProgress(
      phase: '安装完成',
      fraction: 1,
      bytesPerSecond: 0,
      eta: Duration.zero,
      log: List.of(log),
      done: true,
    );
  }

  @override
  Stream<InstallProgress> uninstall(UninstallRequest request) async* {
    final log = <String>[];
    const files = [
      '移除 · assets\\core.pkg',
      '移除 · assets\\market-90d.db',
      '移除 · 系统注册表项',
      '移除 · 开始菜单与快捷方式',
      '清空 · 安装目录',
    ];
    for (var i = 0; i < files.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      log.add(files[i]);
      yield InstallProgress(
        phase: '正在移除程序文件…',
        fraction: (i + 1) / files.length,
        eta: Duration(seconds: (files.length - i - 1) * 0.22 ~/ 1),
        log: List.of(log),
      );
    }
    yield InstallProgress(
      phase: '卸载完成',
      fraction: 1,
      eta: Duration.zero,
      log: List.of(log),
      done: true,
    );
  }
}

/// Release 构建找不到 payload.zip 时的兜底：直接给出可读错误。
class MissingPayloadEngine implements InstallEngine {
  @override
  PayloadInfo get payload =>
      const PayloadInfo(packageBytes: 0, requiredBytes: 0, isDemo: false);

  @override
  bool get isDemo => false;

  @override
  InstallManifest? readManifest(String installDir) => null;

  Stream<InstallProgress> _fail() async* {
    yield const InstallProgress(
      phase: '安装包不完整',
      done: true,
      error: '缺少 payload.zip，请重新下载完整安装包。',
      log: ['错误 · 未找到 payload.zip'],
    );
  }

  @override
  Stream<InstallProgress> install(InstallRequest request) => _fail();

  @override
  Stream<InstallProgress> uninstall(UninstallRequest request) => _fail();
}
