/// 数据目录仓储：把「内置基线 / 本地缓存 / 远端」三者的优先级收在一处，
/// 上层（各 feature 的仓储）只调 [loadShard] / [effectiveManifest]。
///
/// 降级顺序（任何一层失败都不抛给 UI）：
///   1. 本地缓存（active，已通过 sha256 校验）
///   2. 内置 assets（随 App 发版，保证首次启动/离线可用）
///   3. null（调用方用代码里的兜底常量或空态）
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_manifest.dart';
import 'package:tlbbtoolkit/core/content/catalog_remote_source.dart';
import 'package:tlbbtoolkit/core/utils/logger.dart';

/// 一次后台检查的结果，便于埋点/设置页展示。
enum CatalogRefreshOutcome {
  /// 未配置远端，或距上次检查不足 TTL。
  skipped,

  /// 服务端返回 304，内容没变。
  notModified,

  /// 已下载并暂存，**下次启动**生效。
  updated,

  /// 网络/解析/校验失败（已静默降级，继续用旧数据）。
  failed,
}

class CatalogRepository {
  CatalogRepository({
    required this.cache,
    required this.bundle,
    this.remote,
    this.ttl = const Duration(hours: 12),
    this.supportedSchemaVersion = 1,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CatalogCache cache;
  final AssetBundle bundle;
  final CatalogRemoteSource? remote;
  final DateTime Function() _now;

  /// 两次远端检查的最小间隔。
  final Duration ttl;

  /// 客户端能解析的最大 schema 主版本；更高的版本会被忽略（等 App 升级）。
  final int supportedSchemaVersion;

  /// 内置基线的固定路径；分片按 `assets/catalog/<kind>.json` 约定命名。
  static const String bundledManifestPath = 'assets/catalog/manifest.json';

  static String bundledShardPath(String kind) => 'assets/catalog/$kind.json';

  /// 启动时调用一次：把上次下载好的 pending 激活。
  ///
  /// 放在启动阶段而不是下载完成时，是为了**不在会话中途换数据**，
  /// 避免页面正在读的列表突然变长/变短。
  Future<void> init() async {
    try {
      await cache.promotePending();
    } catch (e, s) {
      Logger.instance.error('Catalog', '激活待更新数据失败: $e', s);
    }
  }

  /// 当前应当使用的清单：缓存优先，否则内置基线，最后空清单。
  Future<CatalogManifest> effectiveManifest() async {
    final cached = await cache.readManifest();
    if (cached != null && !cached.isEmpty) return cached;
    return _bundledManifest();
  }

  /// 读取分片原文；读不到返回 null（调用方自行决定兜底）。
  Future<String?> loadShard(String kind) async {
    final cached = await cache.readShard(kind);
    if (cached != null) return cached;
    return _loadBundled(bundledShardPath(kind));
  }

  /// 后台检查一次远端更新；**不阻塞 UI，也不抛异常**。
  Future<CatalogRefreshOutcome> refresh({bool force = false}) async {
    final source = remote;
    if (source == null) return CatalogRefreshOutcome.skipped;

    try {
      if (!force && await _isFresh()) return CatalogRefreshOutcome.skipped;

      // 先记检查时间：失败也按 TTL 退避，避免每次启动都打服务端
      await cache.writeLastCheck(_now());

      final etag = await cache.readEtag();
      final res = await source.fetchManifest(etag: etag);
      if (res.notModified) return CatalogRefreshOutcome.notModified;

      final raw = res.body!;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('manifest 不是 JSON 对象');
      }
      final manifest = CatalogManifest.fromJson(decoded);
      if (manifest.schemaVersion > supportedSchemaVersion) {
        Logger.instance.debug(
          'Catalog',
          '忽略 schema ${manifest.schemaVersion} 的远端数据（客户端支持到 $supportedSchemaVersion）',
        );
        return CatalogRefreshOutcome.failed;
      }
      if (manifest.isEmpty) return CatalogRefreshOutcome.notModified;

      final shards = <String, String>{};
      for (final file in manifest.files.values) {
        shards[file.kind] = await source.fetchShard(file.kind);
      }

      await cache.stage(manifestRaw: raw, shards: shards, etag: res.etag);
      Logger.instance.debug(
        'Catalog',
        '已暂存 ${shards.length} 个分片（${manifest.dataVersion}），下次启动生效',
      );
      return CatalogRefreshOutcome.updated;
    } catch (e, s) {
      // 网络异常、解析失败、磁盘写失败 —— 都只降级，不影响使用
      Logger.instance.error('Catalog', '远端检查失败: $e', s);
      return CatalogRefreshOutcome.failed;
    }
  }

  Future<bool> _isFresh() async {
    final last = await cache.readLastCheck();
    if (last == null) return false;
    return _now().difference(last) < ttl;
  }

  Future<CatalogManifest> _bundledManifest() async {
    final raw = await _loadBundled(bundledManifestPath);
    if (raw == null) return CatalogManifest.empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return CatalogManifest.empty;
      return CatalogManifest.fromJson(decoded);
    } catch (e, s) {
      Logger.instance.error('Catalog', '内置 manifest 解析失败: $e', s);
      return CatalogManifest.empty;
    }
  }

  /// 内置资产缺失是**正常情况**（数据还没迁到 catalog），不记错误。
  Future<String?> _loadBundled(String path) async {
    try {
      return await bundle.loadString(path);
    } catch (_) {
      return null;
    }
  }
}
