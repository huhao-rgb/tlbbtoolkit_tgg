import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/content/catalog_remote_source.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/core/content/catalog_sync.dart';

import 'catalog_fixtures.dart';
import 'fake_asset_bundle.dart';
import 'fake_catalog_storage.dart';

/// 可编排的远端源：不联网，直接给出 manifest / 分片。
class _FakeRemote extends CatalogRemoteSource {
  _FakeRemote({this.manifest, this.shards = const {}, this.notModified = false})
    : super(Dio(), baseUrl: 'https://example.invalid');

  final String? manifest;
  final Map<String, String> shards;
  final bool notModified;

  @override
  Future<CatalogFetch> fetchManifest({String? etag}) async {
    if (notModified) return const CatalogFetch.notModified();
    return CatalogFetch.ok(body: manifest!, etag: '"etag"');
  }

  @override
  Future<String> fetchShard(String kind) async => shards[kind]!;
}

void main() {
  late FakeCatalogStorage storage;
  late CatalogCache cache;

  setUp(() {
    storage = FakeCatalogStorage();
    cache = CatalogCache(storage);
  });

  CatalogRepository buildRepo(CatalogRemoteSource remote) => CatalogRepository(
    cache: cache,
    bundle: FakeAssetBundle(const {}),
    remote: remote,
    now: () => DateTime.utc(2026, 11, 16, 10),
  );

  ProviderContainer makeContainer(CatalogRepository repo) {
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWith((ref) async => repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('同步成功 → 状态 done，并 bump 版本号让页面重建', () async {
    final repo = buildRepo(
      _FakeRemote(
        manifest: manifestJson({'job.artifacts': '{"v":2}'}),
        shards: {'job.artifacts': '{"v":2}'},
      ),
    );
    final container = makeContainer(repo);

    expect(container.read(catalogRevisionProvider), 0);
    expect(
      container.read(catalogSyncControllerProvider).status,
      CatalogSyncStatus.idle,
    );

    await container.read(catalogSyncControllerProvider.notifier).sync();

    final state = container.read(catalogSyncControllerProvider);
    expect(state.status, CatalogSyncStatus.done);
    expect(state.message, '已更新到最新数据');
    expect(container.read(catalogRevisionProvider), 1);
    // 立即生效：读到的就是新分片
    expect(await repo.loadShard('job.artifacts'), '{"v":2}');
  });

  test('没有新版本 → done + 已是最新，版本号不动', () async {
    final repo = buildRepo(_FakeRemote(notModified: true));
    final container = makeContainer(repo);

    await container.read(catalogSyncControllerProvider.notifier).sync();

    final state = container.read(catalogSyncControllerProvider);
    expect(state.status, CatalogSyncStatus.done);
    expect(state.message, '已是最新数据，无需更新');
    expect(container.read(catalogRevisionProvider), 0);
  });

  test('未配置远端 → failed 并提示使用内置数据', () async {
    final repo = CatalogRepository(
      cache: cache,
      bundle: FakeAssetBundle(const {}),
      now: () => DateTime.utc(2026, 11, 16, 10),
    );
    final container = makeContainer(repo);

    await container.read(catalogSyncControllerProvider.notifier).sync();

    final state = container.read(catalogSyncControllerProvider);
    expect(state.status, CatalogSyncStatus.failed);
    expect(state.message, contains('内置数据'));
  });
}
