import 'package:flutter/foundation.dart';

import 'package:tlbbtoolkit/core/storage/secure_kv_store.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';

/// 配对凭据**写入/清除失败**时抛出。
///
/// 这是必须让用户知道的失败：配对没真正保存下来，下次启动仍会显示「未配对」。
class RegPairingStoreException implements Exception {
  const RegPairingStoreException(this.message);

  final String message;

  @override
  String toString() => 'RegPairingStoreException($message)';
}

/// 配对凭据的本机安全存储（Keychain / Keystore / libsecret / 凭据管理器）。
///
/// 只存一条记录：`masterKey` 泄漏等于「账号名单 + 回归记录」全泄漏，
/// 因此**绝不能**明文进 `LocalStorage`（SharedPreferences 明文可读）。
///
/// 成败策略刻意不对称：
/// - [read] **自愈**：读失败（典型场景是 Android 换机恢复后 Keystore 密钥丢失，
///   老密文永远解不开）时清掉坏记录并返回 `null`，用户看到「未配对」重新配对即可，
///   不会卡在一个无法解释的错误态；
/// - [write] / [clear] **抛出**：写不进去必须立刻让用户知道。
class RegPairingStore {
  const RegPairingStore(this._store);

  /// 存储键（带版本号，便于将来换格式）。
  static const String key = 'tgg-reg-pairing-v1';

  final SecureKvStore _store;

  /// 读取本机配对；未配对、或记录已损坏（并已清理）时返回 `null`。
  Future<RegPairing?> read() async {
    final String? raw;
    try {
      raw = await _store.read(key);
    } catch (e) {
      debugPrint('卡回归配对读取失败，按未配对处理：$e');
      await _clearQuietly();
      return null;
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      return RegPairing.decode(raw);
    } on FormatException catch (e) {
      debugPrint('卡回归配对记录已损坏，已清理：${e.message}');
      await _clearQuietly();
      return null;
    }
  }

  /// 保存配对；写入失败抛 [RegPairingStoreException]。
  Future<void> write(RegPairing pairing) async {
    try {
      await _store.write(key, pairing.encode());
    } catch (e) {
      throw RegPairingStoreException('无法写入本机安全存储：$e');
    }
  }

  /// 清除配对（解除云同步）；失败抛 [RegPairingStoreException]。
  Future<void> clear() async {
    try {
      await _store.delete(key);
    } catch (e) {
      throw RegPairingStoreException('无法清除本机安全存储：$e');
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await _store.delete(key);
    } catch (e) {
      debugPrint('卡回归配对记录清理失败（忽略）：$e');
    }
  }
}
