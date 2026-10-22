import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tiangongge_installer/src/engine/install_engine.dart';
import 'package:tiangongge_installer/src/engine/models.dart';
import 'package:tiangongge_installer/src/engine/paths.dart';
import 'package:tiangongge_installer/src/engine/shell_integration.dart';

void main() {
  late Directory tmp;
  late String payloadPath;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('tg_installer_test_');
    final archive = Archive()
      ..addFile(ArchiveFile('tlbbtoolkit.exe', 7, 'MZ fake'.codeUnits))
      ..addFile(
        ArchiveFile(
          'data/flutter_assets/assets/beast.json',
          5,
          'hello'.codeUnits,
        ),
      )
      ..addFile(ArchiveFile('offline/market.db', 8, 'offline!'.codeUnits));
    final bytes = ZipEncoder().encode(archive, level: 0);
    payloadPath = p.join(tmp.path, 'payload.zip');
    File(payloadPath).writeAsBytesSync(bytes);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  ArchiveInstallEngine engine() => ArchiveInstallEngine(
    payloadPath: payloadPath,
    payload: PayloadInfo(
      packageBytes: File(payloadPath).lengthSync(),
      requiredBytes: 40 * 1024 * 1024,
      isDemo: false,
    ),
    shell: const NoopShellIntegration(),
    dataDirOverride: p.join(tmp.path, 'data'),
    provisionUninstaller: false,
  );

  test('安装会解压 payload、写清单，并按组件跳过离线数据', () async {
    final installDir = p.join(tmp.path, 'install');
    final events = await engine()
        .install(
          InstallRequest(
            installDir: installDir,
            components: const {InstallComponent.desktopShortcut},
            version: '1.13.0',
          ),
        )
        .toList();

    expect(events.last.done, isTrue);
    expect(events.last.error, isNull);
    expect(events.last.fraction, 1);
    expect(events.any((e) => e.log.isNotEmpty), isTrue);

    expect(File(p.join(installDir, 'tlbbtoolkit.exe')).existsSync(), isTrue);
    expect(
      File(p.join(installDir, 'data/flutter_assets/assets/beast.json'))
          .existsSync(),
      isTrue,
    );
    expect(
      File(p.join(installDir, 'offline/market.db')).existsSync(),
      isFalse,
      reason: '未勾选离线数据包时不应解压 offline/',
    );

    final manifestFile = File(AppPaths.manifestPath(installDir));
    expect(manifestFile.existsSync(), isTrue);
    final manifest = InstallManifest.decode(manifestFile.readAsStringSync());
    expect(manifest?.version, '1.13.0');
    expect(manifest?.components, contains('desktopShortcut'));
  });

  test('勾选离线数据包时会解压 offline 目录', () async {
    final installDir = p.join(tmp.path, 'install2');
    await engine()
        .install(
          InstallRequest(
            installDir: installDir,
            components: const {
              InstallComponent.desktopShortcut,
              InstallComponent.offlineData,
            },
            version: '1.13.0',
          ),
        )
        .toList();

    expect(File(p.join(installDir, 'offline/market.db')).existsSync(), isTrue);
  });

  test('卸载会移除程序文件，并按选择保留或删除用户数据', () async {
    final installDir = p.join(tmp.path, 'install3');
    final dataDir = p.join(tmp.path, 'data');
    Directory(dataDir).createSync(recursive: true);
    File(p.join(dataDir, 'settings.json')).writeAsStringSync('{}');

    final installEngine = engine();
    await installEngine
        .install(
          InstallRequest(
            installDir: installDir,
            components: const {InstallComponent.offlineData},
            version: '1.13.0',
          ),
        )
        .toList();

    final kept = await installEngine
        .uninstall(UninstallRequest(installDir: installDir, keepUserData: true))
        .toList();
    expect(kept.last.done, isTrue);
    expect(File(p.join(installDir, 'tlbbtoolkit.exe')).existsSync(), isFalse);
    expect(File(p.join(dataDir, 'settings.json')).existsSync(), isTrue);

    await installEngine
        .install(
          InstallRequest(
            installDir: installDir,
            components: const {},
            version: '1.13.0',
          ),
        )
        .toList();
    final removed = await installEngine
        .uninstall(
          UninstallRequest(installDir: installDir, keepUserData: false),
        )
        .toList();
    expect(removed.last.done, isTrue);
    expect(Directory(dataDir).existsSync(), isFalse);
  });
}
