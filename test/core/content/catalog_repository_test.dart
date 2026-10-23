import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_remote_source.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';

import 'catalog_fixtures.dart';
import 'fake_asset_bundle.dart';
import 'fake_catalog_storage.dart';

/// 可编排的远端源：不联网，直接给出 manifest / 分片。
class FakeRemote extends CatalogRemoteSource {
  FakeRemote({
    this.manifest,
    this.shards = const {},
    this.notModified = false,
    this.error,
  }) : super(Dio(), baseUrl: 'https://example.invalid');

  final String? manifest;
  final Map<String, String> shards;
  final bool notModified;
  final Object? error;

  String? lastEtag;
  int manifestCalls = 0;

  @override
  Future<CatalogFetch> fetchManifest({String? etag}) async {
    manifestCalls += 1;
    lastEtag = etag;
    if (error != null) throw error!;
    if (notModified) return const CatalogFetch.notModified();
    return CatalogFetch.ok(body: manifest!, etag: '"server-etag"');
  }

  @override
  Future<String> fetchShard(String kind) async {
    final body = shards[kind];
    if (body == null) throw StateError('没有分片 $kind');
    return body;
  }
}

void main() {
  late FakeCatalogStorage storage;
  late CatalogCache cache;

  setUp(() {
    storage = FakeCatalogStorage();
    cache = CatalogCache(storage);
  });

  CatalogRepository build({
    CatalogRemoteSource? remote,
    Map<String, String> assets = const {},
    Duration ttl = const Duration(hours: 12),
    DateTime? now,
    int supportedSchemaVersion = 1,
  }) => CatalogRepository(
    cache: cache,
    bundle: FakeAssetBundle(assets),
    remote: remote,
    ttl: ttl,
    supportedSchemaVersion: supportedSchemaVersion,
    now: () => now ?? DateTime.utc(2026, 10, 23, 10),
  );

  group('读取优先级', () {
    test('没有缓存 → 用内置 assets', () async {
      final repo = build(
        assets: {
          CatalogRepository.bundledManifestPath: manifestJson({
            'job.artifacts': '{"v":0}',
          }),
          CatalogRepository.bundledShardPath('job.artifacts'): '{"v":0}',
        },
      );

      expect(await repo.loadShard('job.artifacts'), '{"v":0}');
      expect((await repo.effectiveManifest()).files.keys, ['job.artifacts']);
    });

    test('有缓存 → 缓存优先于内置', () async {
      await cache.stage(
        manifestRaw: manifestJson({'job.artifacts': '{"v":2}'}),
        shards: {'job.artifacts': '{"v":2}'},
      );
      await cache.promotePending();

      final repo = build(
        assets: {
          CatalogRepository.bundledManifestPath: manifestJson({
            'job.artifacts': '{"v":0}',
          }),
          CatalogRepository.bundledShardPath('job.artifacts'): '{"v":0}',
        },
      );

      expect(await repo.loadShard('job.artifacts'), '{"v":2}');
      expect((await repo.effectiveManifest()).dataVersion, '2026.10.23.1');
    });

    test('既没缓存也没内置（数据尚未迁移）→ 空清单 + null，不抛异常', () async {
      final repo = build();

      expect(await repo.loadShard('job.artifacts'), isNull);
      expect((await repo.effectiveManifest()).isEmpty, isTrue);
    });
  });

  group('refresh', () {
    test('未配置远端 → skipped，不写检查时间', () async {
      final repo = build();
      expect(await repo.refresh(), CatalogRefreshOutcome.skipped);
      expect(await cache.readLastCheck(), isNull);
    });

    test('TTL 内 → skipped，不发请求', () async {
      await cache.writeLastCheck(DateTime.utc(2026, 10, 23, 9, 30));
      final remote = FakeRemote(
        manifest: manifestJson({'job.artifacts': '{}'}),
      );
      final repo = build(remote: remote, now: DateTime.utc(2026, 10, 23, 10));

      expect(await repo.refresh(), CatalogRefreshOutcome.skipped);
      expect(remote.manifestCalls, 0);
    });

    test('304 → notModified', () async {
      final remote = FakeRemote(notModified: true);
      final repo = build(remote: remote);

      expect(await repo.refresh(), CatalogRefreshOutcome.notModified);
    });

    test('新版本 → 暂存，下次 init 激活后才生效', () async {
      final body = '{"v":2}';
      final remote = FakeRemote(
        manifest: manifestJson({'job.artifacts': body}),
        shards: {'job.artifacts': body},
      );
      final repo = build(remote: remote);

      expect(await repo.refresh(), CatalogRefreshOutcome.updated);
      // 本次会话仍是旧数据
      expect(await repo.loadShard('job.artifacts'), isNull);

      // 模拟重启
      final next = build(remote: remote);
      await next.init();
      expect(await next.loadShard('job.artifacts'), body);
    });

    test('携带上次缓存的 ETag 做条件请求', () async {
      await cache.stage(
        manifestRaw: manifestJson({'job.artifacts': '{}'}),
        shards: {'job.artifacts': '{}'},
        etag: '"cached-etag"',
      );
      await cache.promotePending();

      final remote = FakeRemote(notModified: true);
      await build(remote: remote).refresh();
      expect(remote.lastEtag, '"cached-etag"');
    });

    test('schema 太新 → failed，且不暂存', () async {
      final remote = FakeRemote(
        manifest: manifestJson({'job.artifacts': '{}'}, schemaVersion: 2),
        shards: {'job.artifacts': '{}'},
      );
      final repo = build(remote: remote, supportedSchemaVersion: 1);

      expect(await repo.refresh(), CatalogRefreshOutcome.failed);
      expect(storage.values.keys.any((k) => k.startsWith('pending/')), isFalse);
    });

    test('网络异常 → failed，不抛给调用方', () async {
      final remote = FakeRemote(
        error: DioException(requestOptions: RequestOptions(path: '/')),
      );
      final repo = build(remote: remote);

      expect(await repo.refresh(), CatalogRefreshOutcome.failed);
    });

    test('空清单不会被当成更新', () async {
      final remote = FakeRemote(manifest: manifestJson({}));
      expect(
        await build(remote: remote).refresh(),
        CatalogRefreshOutcome.notModified,
      );
    });
  });
}
