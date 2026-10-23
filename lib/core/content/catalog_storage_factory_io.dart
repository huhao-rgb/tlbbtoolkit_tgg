import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/content/catalog_storage.dart';

/// 原生（Android / iOS / 桌面）：落在应用支持目录下的 `catalog/`。
///
/// 用文件而不是 SharedPreferences：后者启动时会整包读进内存，
/// 几百分片的 JSON 会白白拖慢冷启动。
Future<CatalogStorage> openCatalogStorage({
  required SharedPreferences prefs,
}) async {
  final support = await getApplicationSupportDirectory();
  final root = Directory('${support.path}/catalog');
  await root.create(recursive: true);
  return FileCatalogStorage(root);
}

/// 每个 key 落一个文件；key 里的 `/` 用 `__` 扁平化，省掉多级目录创建。
class FileCatalogStorage implements CatalogStorage {
  FileCatalogStorage(this.root);

  final Directory root;

  File _file(String key) => File('${root.path}/${key.replaceAll('/', '__')}');

  @override
  Future<String?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// 先写临时文件再 rename：避免进程被杀时留下半截 JSON。
  @override
  Future<void> write(String key, String value) async {
    final file = _file(key);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(value, flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> delete(String key) async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<String>> keys() async {
    if (!await root.exists()) return const [];
    return [
      await for (final entity in root.list())
        if (entity is File && !entity.path.endsWith('.tmp'))
          entity.uri.pathSegments.last.replaceAll('__', '/'),
    ];
  }
}
