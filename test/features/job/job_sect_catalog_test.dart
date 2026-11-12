import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/core/content/catalog_storage.dart';
import 'package:tlbbtoolkit/features/job/data/job_catalog.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect_info.dart';

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

/// 模拟 2026-11-05 的旧分片：还没有 `dmg` 字段。
Map<String, Object?> _oldShardDocument() => {
  'schemaVersion': 1,
  'dataVersion': '2026.11.05.80a8fb42',
  'kind': 'job.sect_info',
  'items': {
    'shaolin': {
      'intro': '旧分片的少林简介',
      'atk': ['玄攻 · 主属性攻'],
      'atkColor': 'purple',
      'main': '体力 · 力量',
      'atype': '外功 · 坦辅',
      'traits': [
        {'label': '定位', 'value': '近战攻击，单玄属性'},
      ],
      'suit': '适合喜欢正面承伤、保护队友的玩家。',
      'bg': '中原第一名刹。',
      'life': <Object?>[],
    },
  },
};

String _manifestOf(String shardRaw) => jsonEncode({
  'schemaVersion': 1,
  'dataVersion': '2026.11.05.80a8fb42',
  'files': [
    {
      'kind': jobSectInfoKind,
      'schemaVersion': 1,
      'dataVersion': '2026.11.05.80a8fb42',
      'sha256': sha256Of(shardRaw),
      'bytes': utf8.encode(shardRaw).length,
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('门派介绍分片：旧数据不遮蔽新字段', () {
    test('缓存里是旧分片（无 dmg）时，伤害系数回落到内置常量', () async {
      final shardRaw = jsonEncode(_oldShardDocument());
      final storage = _FakeStorage({
        'active/manifest': _manifestOf(shardRaw),
        'active/shard/$jobSectInfoKind': shardRaw,
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

      final catalog = await container.read(jobSectInfoCatalogProvider.future);

      // 正文仍以分片为准（用户拿到的远端文案不会被内置常量顶掉）
      expect(catalog['shaolin']!.intro, '旧分片的少林简介');
      // 分片缺的 dmg 由内置常量补齐
      final dmg = catalog['shaolin']!.dmg;
      expect(dmg, isNotNull);
      expect(dmg!.phys, closeTo(0.0575, 1e-9));
      expect(dmg.xuan, closeTo(1.5, 1e-9));
    });

    test('分片自带 dmg 时以分片为准', () {
      final shard = {
        'shaolin': JobSectInfo(
          intro: '分片简介',
          atk: const ['玄攻 · 主属性攻'],
          atkColor: 'purple',
          main: '体力 · 力量',
          atype: '外功 · 坦辅',
          traits: const [],
          suit: '适合人群',
          dmg: const JobDamageCoef(
            phys: 9,
            magic: 9,
            ice: 9,
            fire: 9,
            xuan: 9,
            poison: 9,
          ),
        ),
      };

      final merged = withBuiltinSectFallback(shard);

      expect(merged['shaolin']!.intro, '分片简介');
      expect(merged['shaolin']!.dmg!.phys, 9);
    });

    test('内置常量里没有的门派保持原样', () {
      final shard = {
        'unknown-sect': const JobSectInfo(
          intro: '新门派简介',
          atk: ['毒攻 · 主属性攻'],
          atkColor: 'green',
          main: '灵气 · 体力',
          atype: '内功 · 毒系',
          traits: [],
          suit: '适合人群',
        ),
      };

      final merged = withBuiltinSectFallback(shard);

      expect(merged['unknown-sect']!.dmg, isNull);
      expect(merged['unknown-sect']!.intro, '新门派简介');
    });
  });
}
