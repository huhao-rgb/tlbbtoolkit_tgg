import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/core/content/catalog_storage.dart';
import 'package:tlbbtoolkit/features/job/data/job_catalog.dart';

/// 内存版缓存介质，避免单测碰文件系统。
class _FakeStorage implements CatalogStorage {
  _FakeStorage(this.values);

  final Map<String, String> values;

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

/// 带 `rows` / `edges` 的武道分片（慕容截图收录后的结构）。
Map<String, Object?> _shardWithTree() => {
  'schemaVersion': 1,
  'dataVersion': '2026.11.17.f02e1a6e',
  'kind': jobWudaoKind,
  'items': {
    'tierNames': ['一重', '二重', '三重', '四重'],
    'schools': {
      'murong': [
        {
          'name': '逆锋',
          'passive': {'name': '命不由天', 'desc': '借力返施的冷却时间改为10秒。'},
          'layers': [
            {
              'nodes': [
                for (var i = 0; i < 10; i++) {'name': '节点$i', 'effect': '效果$i'},
              ],
              'rows': [2, 3, 2, 3],
              'edges': [
                [0, 2],
                [0, 3],
              ],
            },
            {
              // 老分片没有 rows/edges
              'nodes': [
                {'name': '旧节点', 'effect': '旧效果'},
              ],
            },
          ],
        },
      ],
    },
  },
};

String _manifestOf(String shardRaw) => jsonEncode({
  'schemaVersion': 1,
  'dataVersion': '2026.11.17.f02e1a6e',
  'files': [
    {
      'kind': jobWudaoKind,
      'schemaVersion': 1,
      'dataVersion': '2026.11.17.f02e1a6e',
      'sha256': sha256Of(shardRaw),
      'bytes': utf8.encode(shardRaw).length,
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('武道分片：rows / edges 能解析，缺失时为空（不至于崩）', () async {
    final shardRaw = jsonEncode(_shardWithTree());
    final storage = _FakeStorage({
      'active/manifest': _manifestOf(shardRaw),
      'active/shard/$jobWudaoKind': shardRaw,
    });

    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWith(
          (ref) async => CatalogRepository(
            cache: CatalogCache(storage),
            bundle: rootBundle,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final catalog = await container.read(jobWudaoCatalogProvider.future);
    final school = catalog.schools['murong']!.single;

    final tree = school.layers[0];
    expect(tree.rows, [2, 3, 2, 3]);
    expect(tree.edges, [
      [0, 2],
      [0, 3],
    ]);
    expect(tree.hasTree, isTrue);

    // 老分片（无 rows/edges）解析为 null，弹窗按单行平铺兜底
    final plain = school.layers[1];
    expect(plain.rows, isNull);
    expect(plain.edges, isNull);
    expect(plain.hasTree, isFalse);
  });
}
