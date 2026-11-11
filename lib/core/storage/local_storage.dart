import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 基于 [SharedPreferences] 的轻量 KV 存储封装。
///
/// 通过 [LocalStorage] 统一对外提供本地读写能力，
/// 各 feature 的仓储只依赖它，不直接接触 SharedPreferences，
/// 便于后续替换为 sqlite / hive 等更强的存储实现。
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  /// 读取 JSON 对象，损坏、不是对象或缺失时返回 null。
  ///
  /// 注意：`jsonDecode` 对 `[]` / `"x"` / `123` 这类**合法非对象 JSON**
  /// 不会抛 [FormatException]，若直接 `as Map` 会抛出 `TypeError` 并击穿
  /// 调用方（设置页在根组件 build 时读取，会直接白屏）。因此先判类型。
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } on FormatException {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
