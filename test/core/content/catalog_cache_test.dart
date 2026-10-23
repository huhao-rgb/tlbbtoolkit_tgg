import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_manifest.dart';

import 'catalog_fixtures.dart';
import 'fake_catalog_storage.dart';

void main() {
  late FakeCatalogStorage storage;
  late CatalogCache cache;

  setUp(() {
    storage = FakeCatalogStorage();
    cache = CatalogCache(storage);
  });

  test('stage 只写 pending，不碰 active', () async {
    await cache.stage(
      manifestRaw: manifestJson({'job.artifacts': '{"v":2}'}),
      shards: {'job.artifacts': '{"v":2}'},
      etag: '"e2"',
    );

    expect(await cache.readManifest(), isNull);
    expect(await cache.readShard('job.artifacts'), isNull);
    expect(storage.values.keys, contains('pending/manifest'));
  });

  test('promotePending：校验通过才顶替 active', () async {
    await cache.stage(
      manifestRaw: manifestJson({'job.artifacts': '{"v":2}'}),
      shards: {'job.artifacts': '{"v":2}'},
      etag: '"e2"',
    );

    expect(await cache.promotePending(), isTrue);
    expect(await cache.readShard('job.artifacts'), '{"v":2}');
    expect(await cache.readEtag(), '"e2"');

    final manifest = await cache.readManifest();
    expect(manifest!.files.keys, ['job.artifacts']);

    // pending 已清空
    expect(storage.values.keys.any((k) => k.startsWith('pending/')), isFalse);
  });

  test('promotePending：分片哈希不符 → 整包丢弃，active 保持原样', () async {
    // 先放一套正常的 active
    await cache.stage(
      manifestRaw: manifestJson({'job.artifacts': '{"v":1}'}),
      shards: {'job.artifacts': '{"v":1}'},
    );
    await cache.promotePending();

    // 再放一套坏的 pending（清单声明的哈希与内容不匹配）
    await cache.stage(
      manifestRaw: manifestJson({'job.artifacts': '{"v":2}'}),
      shards: {'job.artifacts': 'TAMPERED'},
    );

    expect(await cache.promotePending(), isFalse);
    expect(await cache.readShard('job.artifacts'), '{"v":1}');
    expect(storage.values.keys.any((k) => k.startsWith('pending/')), isFalse);
  });

  test('promotePending：缺分片 / manifest 损坏 → 返回 false 且不抛异常', () async {
    await cache.stage(
      manifestRaw: manifestJson({
        'job.artifacts': '{"v":2}',
        'pet.beast_spirits': '{}',
      }),
      shards: {'job.artifacts': '{"v":2}'}, // 故意少一个
    );
    expect(await cache.promotePending(), isFalse);

    await storage.write('pending/manifest', '{bad json');
    expect(await cache.promotePending(), isFalse);
    expect(await cache.readManifest(), isNull);
  });

  test('空清单不会被激活（避免远端误发把数据清空）', () async {
    await cache.stage(manifestRaw: manifestJson({}), shards: {});
    expect(await cache.promotePending(), isFalse);
  });

  test('上次检查时间可读回；clear 清空全部', () async {
    final at = DateTime.utc(2026, 10, 23, 10);
    await cache.writeLastCheck(at);
    expect(await cache.readLastCheck(), at);

    await cache.stage(
      manifestRaw: manifestJson({'job.artifacts': '{}'}),
      shards: {'job.artifacts': '{}'},
    );
    await cache.promotePending();

    await cache.clear();
    expect(await cache.readManifest(), isNull);
    expect(await cache.readLastCheck(), isNull);
    expect(await cache.readShard('job.artifacts'), isNull);
  });

  test('CatalogManifest 解析：缓存里是坏 JSON 时 readManifest 返回 null', () async {
    await storage.write('active/manifest', 'not json');
    expect(await cache.readManifest(), isNull);
    expect(CatalogManifest.empty.isEmpty, isTrue);
  });
}
