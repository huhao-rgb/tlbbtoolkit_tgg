import 'dart:io';

import 'package:path/path.dart' as p;

/// 所有路径只在这里推导，安装引擎与系统集成都不自己拼路径。
abstract final class AppPaths {
  static const appName = '天工阁';
  static const appId = '{8F3C2B10-4E7A-4C1D-9B22-5A6E7C8D9F01}';
  static const appExeName = 'tlbbtoolkit.exe';
  static const installerExeName = 'tiangongge_installer.exe';
  static const uninstallerFolderName = '.uninstaller';
  static const manifestName = 'install.json';

  static const uninstallKey =
      r'Software\Microsoft\Windows\CurrentVersion\Uninstall'
      r'\{8F3C2B10-4E7A-4C1D-9B22-5A6E7C8D9F01}';

  static const autostartKey = r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const autostartValueName = 'TiangongGe';

  static String get home =>
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.current.path;

  static String get localAppData {
    if (Platform.isWindows) {
      return Platform.environment['LOCALAPPDATA'] ??
          p.join(home, 'AppData', 'Local');
    }
    return p.join(home, 'Library', 'Application Support');
  }

  static String get roamingAppData {
    if (Platform.isWindows) {
      return Platform.environment['APPDATA'] ??
          p.join(home, 'AppData', 'Roaming');
    }
    return p.join(home, 'Library', 'Application Support');
  }

  static String get defaultInstallDir {
    if (Platform.isWindows) {
      return p.join(localAppData, 'Programs', 'TiangongGe');
    }
    return p.join(home, 'Applications', 'TiangongGe');
  }

  static String get dataDir => p.join(roamingAppData, 'TiangongGe');

  static String get desktopDir => p.join(home, 'Desktop');

  static String get startMenuDir {
    if (Platform.isWindows) {
      return p.join(
        roamingAppData,
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
      );
    }
    return p.join(home, 'Applications');
  }

  static String get selfExe => Platform.resolvedExecutable;

  static String get selfDir => p.dirname(selfExe);

  static String installedExe(String installDir) =>
      p.join(installDir, appExeName);

  static String manifestPath(String installDir) =>
      p.join(installDir, manifestName);

  static String uninstallerDir(String installDir) =>
      p.join(installDir, uninstallerFolderName);

  static String uninstallerExe(String installDir) =>
      p.join(uninstallerDir(installDir), installerExeName);

  static String desktopShortcutPath() => p.join(desktopDir, '$appName.lnk');

  static String startMenuShortcutPath() => p.join(startMenuDir, '$appName.lnk');

  /// 安装包（payload.zip）候选位置：构建脚本会放在 exe 同目录或 flutter_assets 下。
  static List<String> payloadCandidates() {
    final override = Platform.environment['TIANGONGGE_PAYLOAD'];
    return [
      if (override != null && override.isNotEmpty) override,
      p.join(selfDir, 'payload.zip'),
      p.join(selfDir, 'assets', 'payload', 'payload.zip'),
      p.join(
        selfDir,
        'data',
        'flutter_assets',
        'assets',
        'payload',
        'payload.zip',
      ),
    ];
  }

  static String? resolvePayload() {
    for (final candidate in payloadCandidates()) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }
}
