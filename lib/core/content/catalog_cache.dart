/// 数据目录的本地缓存：**待激活**与**已激活**两套 key。
///
/// 语义（对应「下次启动生效」）：
///   · 远端下载完成 → 全部写进 `pending/*`，先不碰正在用的数据；
///   · 下次启动时 [promotePending] 校验每个分片的 sha256，通过才整体顶替 `active/*`；
///   · 任何一步不完整/被篡改 → 丢弃 pending，继续用原来的 active 或内置基线。
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:tlbbtoolkit/core/content/catalog_manifest.dart';
import 'package:tlbbtoolkit/core/content/catalog_storage.dart';

/// 字符串的 sha256（小写十六进制），与服务端 `crypto.createHash('sha256')` 一致。
String sha256Of(String text) => sha256.convert(utf8.encode(text)).toString();

class CatalogCache {
  CatalogCache(this._storage);

  final CatalogStorage _storage;

  static const String _activeManifest = 'active/manifest';
  static const String _activeEtag = 'active/etag';
  static const String _pendingManifest = 'pending/manifest';
  static const String _pendingEtag = 'pending/etag';
  static const String _lastCheck = 'last-check';

  static const String _activePrefix = 'active/';
  static const String _pendingPrefix = 'pending/';
  static const String _activeShardPrefix = 'active/shard/';
  static const String _pendingShardPrefix = 'pending/shard/';

  /// 当前生效的清单；没有缓存（首次启动 / 已损坏）时返回 null。
  Future<CatalogManifest?> readManifest() async {
    final raw = await _storage.read(_activeManifest);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return CatalogManifest.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 缓存清单的 HTTP ETag，用于下次 `If-None-Match`。
  Future<String?> readEtag() => _storage.read(_activeEtag);

  /// 当前生效的分片原文；未缓存时返回 null。
  Future<String?> readShard(String kind) =>
      _storage.read('$_activeShardPrefix$kind');

  /// 把下载好的内容整体写入 pending（覆盖上一次未激活的残留）。
  Future<void> stage({
    required String manifestRaw,
    required Map<String, String> shards,
    String? etag,
  }) async {
    await discardPending();
    await _storage.write(_pendingManifest, manifestRaw);
    if (etag != null && etag.isNotEmpty) {
      await _storage.write(_pendingEtag, etag);
    }
    for (final entry in shards.entries) {
      await _storage.write('$_pendingShardPrefix${entry.key}', entry.value);
    }
  }

  /// 校验并激活 pending。返回是否真的切换成功。
  ///
  /// 只做「全对才换」：任一分片缺失或哈希不符，整包丢弃 —— 半套数据比旧数据更危险。
  Future<bool> promotePending() async {
    final manifestRaw = await _storage.read(_pendingManifest);
    if (manifestRaw == null) return false;

    final CatalogManifest manifest;
    try {
      final decoded = jsonDecode(manifestRaw);
      if (decoded is! Map<String, dynamic>) {
        await discardPending();
        return false;
      }
      manifest = CatalogManifest.fromJson(decoded);
    } catch (_) {
      await discardPending();
      return false;
    }
    if (manifest.isEmpty) {
      await discardPending();
      return false;
    }

    final shards = <String, String>{};
    for (final file in manifest.files.values) {
      final body = await _storage.read('$_pendingShardPrefix${file.kind}');
      if (body == null || sha256Of(body) != file.sha256) {
        await discardPending();
        return false;
      }
      shards[file.kind] = body;
    }

    final etag = await _storage.read(_pendingEtag);

    await _clearPrefix(_activePrefix);
    await _storage.write(_activeManifest, manifestRaw);
    if (etag != null && etag.isNotEmpty) {
      await _storage.write(_activeEtag, etag);
    }
    for (final entry in shards.entries) {
      await _storage.write('$_activeShardPrefix${entry.key}', entry.value);
    }

    await _clearPrefix(_pendingPrefix);
    return true;
  }

  Future<void> discardPending() => _clearPrefix(_pendingPrefix);

  /// 上次检查远端的时间；没有记录返回 null。
  Future<DateTime?> readLastCheck() async {
    final raw = await _storage.read(_lastCheck);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> writeLastCheck(DateTime time) =>
      _storage.write(_lastCheck, time.toIso8601String());

  /// 清空全部缓存（设置页「恢复内置数据」可用）。
  Future<void> clear() async {
    for (final key in await _storage.keys()) {
      await _storage.delete(key);
    }
  }

  Future<void> _clearPrefix(String prefix) async {
    for (final key in await _storage.keys()) {
      if (key.startsWith(prefix)) await _storage.delete(key);
    }
  }
}
