import 'package:tlbbtoolkit/core/content/catalog_storage.dart';

/// 内存版 [CatalogStorage]：让缓存/仓储单测不碰文件系统。
class FakeCatalogStorage implements CatalogStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<List<String>> keys() async => values.keys.toList();
}
