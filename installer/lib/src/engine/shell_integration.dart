import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:tiangongge_installer/src/engine/models.dart';
import 'package:tiangongge_installer/src/engine/paths.dart';
import 'package:win32/win32.dart';

/// 安装器需要的系统集成能力。macOS 预览时使用 [NoopShellIntegration]。
abstract class ShellIntegration {
  String desktopShortcutLink();

  String startMenuShortcutLink();

  Future<void> createShortcut({
    required String linkPath,
    required String target,
    required String workingDirectory,
    String? iconPath,
  });

  Future<void> deleteShortcut(String linkPath);

  Future<void> writeUninstallEntry({
    required InstallManifest manifest,
    required String uninstallerPath,
    required int estimatedBytes,
  });

  Future<void> removeUninstallEntry();

  Future<void> setAutostart({required bool enabled, required String exePath});

  Future<void> launch(String exePath);

  /// 卸载完成后清理卸载器自身目录（仅当运行在 <安装目录>\.uninstaller 时生效）。
  Future<void> scheduleSelfDelete();
}

class NoopShellIntegration implements ShellIntegration {
  const NoopShellIntegration();

  @override
  String desktopShortcutLink() => AppPaths.desktopShortcutPath();

  @override
  String startMenuShortcutLink() => AppPaths.startMenuShortcutPath();

  @override
  Future<void> createShortcut({
    required String linkPath,
    required String target,
    required String workingDirectory,
    String? iconPath,
  }) async {}

  @override
  Future<void> deleteShortcut(String linkPath) async {}

  @override
  Future<void> writeUninstallEntry({
    required InstallManifest manifest,
    required String uninstallerPath,
    required int estimatedBytes,
  }) async {}

  @override
  Future<void> removeUninstallEntry() async {}

  @override
  Future<void> setAutostart({
    required bool enabled,
    required String exePath,
  }) async {}

  @override
  Future<void> launch(String exePath) async {}

  @override
  Future<void> scheduleSelfDelete() async {}
}

class WindowsShellIntegration implements ShellIntegration {
  const WindowsShellIntegration();

  @override
  String desktopShortcutLink() =>
      p.join(_knownFolder(FOLDERID_Desktop), '${AppPaths.appName}.lnk');

  @override
  String startMenuShortcutLink() =>
      p.join(_knownFolder(FOLDERID_Programs), '${AppPaths.appName}.lnk');

  @override
  Future<void> createShortcut({
    required String linkPath,
    required String target,
    required String workingDirectory,
    String? iconPath,
  }) async {
    Directory(p.dirname(linkPath)).createSync(recursive: true);
    _withCom(() {
      final link = createInstance<IShellLink>(ShellLink);
      final persist = IPersistFile.from(link);
      try {
        using((arena) {
          link.setPath(arena.pcwstr(target));
          link.setWorkingDirectory(arena.pcwstr(workingDirectory));
          final icon = iconPath;
          if (icon != null && icon.isNotEmpty) {
            link.setIconLocation(arena.pcwstr(icon), 0);
          }
          persist.save(arena.pcwstr(linkPath), true);
        });
      } finally {
        persist.release();
        link.release();
      }
    });
  }

  @override
  Future<void> deleteShortcut(String linkPath) async {
    final file = File(linkPath);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<void> writeUninstallEntry({
    required InstallManifest manifest,
    required String uninstallerPath,
    required int estimatedBytes,
  }) async {
    final key = _createKey(AppPaths.uninstallKey);
    try {
      _setString(key, 'DisplayName', AppPaths.appName);
      _setString(key, 'DisplayVersion', manifest.version);
      _setString(key, 'Publisher', '天工阁开发组');
      _setString(
        key,
        'DisplayIcon',
        '${AppPaths.installedExe(manifest.installDir)},0',
      );
      _setString(key, 'InstallLocation', manifest.installDir);
      _setString(key, 'UninstallString', '"$uninstallerPath" --uninstall');
      _setString(
        key,
        'QuietUninstallString',
        '"$uninstallerPath" --uninstall --quiet',
      );
      _setDword(key, 'EstimatedSize', (estimatedBytes / 1024).round());
      _setDword(key, 'NoModify', 1);
      _setDword(key, 'NoRepair', 1);
    } finally {
      RegCloseKey(key);
    }
  }

  @override
  Future<void> removeUninstallEntry() async {
    // 重复卸载时键可能已不存在，删除失败不应阻塞流程。
    using<void>((arena) {
      RegDeleteKey(HKEY_CURRENT_USER, arena.pcwstr(AppPaths.uninstallKey));
    });
  }

  @override
  Future<void> setAutostart({
    required bool enabled,
    required String exePath,
  }) async {
    final key = _createKey(AppPaths.autostartKey);
    try {
      if (enabled) {
        _setString(key, AppPaths.autostartValueName, '"$exePath"');
      } else {
        using<void>((arena) {
          RegDeleteValue(key, arena.pcwstr(AppPaths.autostartValueName));
        });
      }
    } finally {
      RegCloseKey(key);
    }
  }

  @override
  Future<void> launch(String exePath) async {
    await Process.start(exePath, const [], mode: ProcessStartMode.detached);
  }

  @override
  Future<void> scheduleSelfDelete() async {
    final dir = Directory(AppPaths.selfDir);
    // 只有从 <安装目录>\.uninstaller 运行时才清理，避免误删开发目录。
    if (p.basename(dir.path) != AppPaths.uninstallerFolderName) return;
    if (!dir.existsSync()) return;
    if (!Platform.isWindows) return;

    // 按用户安装没有管理员权限，MOVEFILE_DELAY_UNTIL_REBOOT 会失败；
    // 改为等本进程退出后由隐藏的 PowerShell 清理卸载器目录。
    final target = dir.path.replaceAll("'", "''");
    final parent = p.dirname(dir.path).replaceAll("'", "''");
    final script = [
      'Start-Sleep -Seconds 2;',
      "Remove-Item -LiteralPath '$target' -Recurse -Force -ErrorAction SilentlyContinue;",
      "if ((Get-ChildItem -LiteralPath '$parent' -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {",
      "Remove-Item -LiteralPath '$parent' -Force -ErrorAction SilentlyContinue }",
    ].join(' ');

    await Process.start('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-Command',
      script,
    ], mode: ProcessStartMode.detached);
  }

  HKEY _createKey(String subKey) {
    final handle = using((arena) {
      final result = arena<Pointer>(sizeOf<Pointer>());
      RegCreateKeyEx(
        HKEY_CURRENT_USER,
        arena.pcwstr(subKey),
        null,
        REG_OPTION_NON_VOLATILE,
        KEY_WRITE,
        null,
        result,
        null,
      ).onSuccess(() {});
      return HKEY(result.value);
    });
    return handle;
  }

  void _setString(HKEY key, String name, String value) {
    using((arena) {
      RegSetValueEx(
        key,
        arena.pcwstr(name),
        REG_SZ,
        arena.pcwstr(value).cast<Uint8>(),
        (value.length + 1) * 2,
      ).onSuccess(() {});
    });
  }

  void _setDword(HKEY key, String name, int value) {
    final data = calloc<Uint32>()..value = value;
    try {
      using((arena) {
        RegSetValueEx(
          key,
          arena.pcwstr(name),
          REG_DWORD,
          data.cast<Uint8>(),
          sizeOf<Uint32>(),
        ).onSuccess(() {});
      });
    } finally {
      free(data);
    }
  }

  String _knownFolder(GUID id) {
    final path = using(
      (arena) => SHGetKnownFolderPath(
        id.toNative(allocator: arena),
        KF_FLAG_DEFAULT,
        null,
      ),
    );
    try {
      return path.toDartString();
    } finally {
      CoTaskMemFree(path);
    }
  }

  T _withCom<T>(T Function() action) {
    final hr = CoInitializeEx(COINIT_APARTMENTTHREADED);
    final ownsCom = !hr.isError;
    try {
      return action();
    } finally {
      if (ownsCom) CoUninitialize();
    }
  }
}

ShellIntegration createShellIntegration() => Platform.isWindows
    ? const WindowsShellIntegration()
    : const NoopShellIntegration();
