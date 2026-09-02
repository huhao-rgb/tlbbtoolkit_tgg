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

  /// 读取 JSON 对象，损坏或缺失时返回 null。
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
