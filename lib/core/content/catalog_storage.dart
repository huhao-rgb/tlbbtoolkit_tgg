/// 数据目录缓存的落地介质抽象。
///
/// 为什么不直接写文件：应用要出 Web，`dart:io` 在浏览器里不可用。
/// 这里把「按 key 存取字符串」抽出来，原生走文件、Web 走 SharedPreferences，
/// 上层的暂存/激活逻辑只写一份。
library;

import 'package:shared_preferences/shared_preferences.dart';

/// 极简 KV 接口（值都是字符串，项目里就是 JSON 文本）。
abstract interface class CatalogStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// 返回**所有** key（调用方自行按前缀过滤）。
  Future<List<String>> keys();
}

/// Web / 无文件系统环境：落在 SharedPreferences（浏览器里是 localStorage）。
class PrefsCatalogStorage implements CatalogStorage {
  PrefsCatalogStorage(this._prefs, {this.prefix = 'tgg-catalog'});

  final SharedPreferences _prefs;
  final String prefix;

  String _k(String key) => '$prefix:$key';

  @override
  Future<String?> read(String key) async => _prefs.getString(_k(key));

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(_k(key), value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(_k(key));
  }

  @override
  Future<List<String>> keys() async => [
    for (final k in _prefs.getKeys())
      if (k.startsWith('$prefix:')) k.substring(prefix.length + 1),
  ];
}
