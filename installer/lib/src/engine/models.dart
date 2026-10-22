import 'dart:convert';

enum InstallComponent { desktopShortcut, autostart, offlineData }

class InstallRequest {
  const InstallRequest({
    required this.installDir,
    required this.components,
    required this.version,
    this.runAfter = true,
  });

  final String installDir;
  final Set<InstallComponent> components;
  final String version;
  final bool runAfter;
}

class UninstallRequest {
  const UninstallRequest({
    required this.installDir,
    required this.keepUserData,
  });

  final String installDir;
  final bool keepUserData;
}

/// 安装 / 卸载过程中的一帧快照。
class InstallProgress {
  const InstallProgress({
    this.phase = '',
    this.fraction = 0,
    this.currentFile,
    this.bytesPerSecond = 0,
    this.eta,
    this.log = const [],
    this.done = false,
    this.error,
  });

  final String phase;
  final double fraction;
  final String? currentFile;
  final double bytesPerSecond;
  final Duration? eta;
  final List<String> log;
  final bool done;
  final Object? error;

  InstallProgress copyWith({
    String? phase,
    double? fraction,
    String? currentFile,
    double? bytesPerSecond,
    Duration? eta,
    List<String>? log,
    bool? done,
    Object? error,
  }) => InstallProgress(
    phase: phase ?? this.phase,
    fraction: fraction ?? this.fraction,
    currentFile: currentFile ?? this.currentFile,
    bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
    eta: eta ?? this.eta,
    log: log ?? this.log,
    done: done ?? this.done,
    error: error ?? this.error,
  );

  static const idle = InstallProgress();
}

/// 写入安装目录的安装清单，供卸载器读取。
class InstallManifest {
  const InstallManifest({
    required this.version,
    required this.installDir,
    required this.dataDir,
    required this.components,
    required this.installedAt,
    required this.installedBytes,
  });

  final String version;
  final String installDir;
  final String dataDir;
  final List<String> components;
  final String installedAt;
  final int installedBytes;

  Map<String, Object?> toJson() => {
    'version': version,
    'installDir': installDir,
    'dataDir': dataDir,
    'components': components,
    'installedAt': installedAt,
    'installedBytes': installedBytes,
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static InstallManifest? decode(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, Object?>) return null;
      return InstallManifest(
        version: json['version'] as String? ?? '',
        installDir: json['installDir'] as String? ?? '',
        dataDir: json['dataDir'] as String? ?? '',
        components: (json['components'] as List?)?.cast<String>() ?? const [],
        installedAt: json['installedAt'] as String? ?? '',
        installedBytes: (json['installedBytes'] as num?)?.toInt() ?? 0,
      );
    } on FormatException {
      return null;
    }
  }
}

/// 安装包信息（安装包体积 / 解压后所需空间）。
class PayloadInfo {
  const PayloadInfo({
    required this.packageBytes,
    required this.requiredBytes,
    required this.isDemo,
  });

  final int packageBytes;
  final int requiredBytes;
  final bool isDemo;
}
