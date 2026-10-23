import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/features/job/data/job_artifact_parser.dart';
import 'package:tlbbtoolkit/features/job/data/job_artifacts_repository.dart';
import 'package:tlbbtoolkit/features/job/domain/job_artifact.dart';

import '../../core/content/fake_asset_bundle.dart';
import '../../core/content/fake_catalog_storage.dart';

/// 用固定分片内容替换 catalog 仓储，验证「分片 → 领域模型」的链路与兜底。
class _StubCatalog extends CatalogRepository {
  _StubCatalog(this.payload)
    : super(
        cache: CatalogCache(FakeCatalogStorage()),
        bundle: FakeAssetBundle({}),
      );

  final String? payload;

  @override
  Future<String?> loadShard(String kind) async =>
      kind == jobArtifactsKind ? payload : null;
}

ProviderContainer _container(String? payload) {
  final container = ProviderContainer(
    overrides: [
      catalogRepositoryProvider.overrideWith(
        (ref) async => _StubCatalog(payload),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

String _shard(Object? items) => jsonEncode({
  'schemaVersion': 1,
  'dataVersion': '2026.10.23.test',
  'kind': jobArtifactsKind,
  'items': items,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseJobArtifacts', () {
    test('解析 weapon / tiers 全部字段', () {
      final parsed = parseJobArtifacts(
        _shard({
          'shaolin': {
            'weapon': '枪棒/刀斧',
            'tiers': [
              {
                'lv': 42,
                'name': '测试刀',
                'intro': '简介',
                'stats': ['攻击 +1', '命中 +2'],
                'extra': '特性',
                'how': ['步骤一', '步骤二'],
              },
            ],
          },
        }),
      );

      final artifact = parsed['shaolin']!;
      expect(artifact.weapon, '枪棒/刀斧');
      expect(artifact.tiers, hasLength(1));
      expect(artifact.tiers.single.lv, 42);
      expect(artifact.tiers.single.name, '测试刀');
      expect(artifact.tiers.single.stats, ['攻击 +1', '命中 +2']);
      expect(artifact.tiers.single.how, ['步骤一', '步骤二']);
    });

    test('坏条目被跳过，不影响其他门派', () {
      final parsed = parseJobArtifacts(
        _shard({
          'good': {
            'weapon': '剑',
            'tiers': [
              // 坏档位：lv 不是 int
              {'lv': '42', 'name': 'x', 'intro': 'x', 'extra': 'x'},
              {'lv': 52, 'name': '好档位', 'intro': '简介', 'extra': '特性'},
            ],
          },
          'bad.sect': 'not-a-map',
          'empty.sect': {'weapon': '刀', 'tiers': []},
        }),
      );

      expect(parsed.keys, ['good']);
      expect(parsed['good']!.tiers.single.name, '好档位');
    });

    test('根结构不合法 → FormatException（由上层兜底）', () {
      expect(() => parseJobArtifacts('[]'), throwsFormatException);
      expect(
        () => parseJobArtifacts(jsonEncode({'schemaVersion': 1})),
        throwsFormatException,
      );
    });
  });

  group('内置资产（随包基线的唯一事实源）', () {
    test('assets/catalog/job.artifacts.json 可解析，且与 kJobArtifacts 一致', () async {
      // 这条测试防止「改了常量却忘记重新导出」导致包内基线过期
      final raw = await rootBundle.loadString(
        'assets/catalog/job.artifacts.json',
      );
      final parsed = parseJobArtifacts(raw);

      expect(parsed.keys, kJobArtifacts.keys);
      for (final entry in kJobArtifacts.entries) {
        final source = entry.value;
        final bundled = parsed[entry.key]!;
        expect(bundled.weapon, source.weapon);
        expect(bundled.tiers.length, source.tiers.length);
        for (var i = 0; i < source.tiers.length; i++) {
          expect(bundled.tiers[i].lv, source.tiers[i].lv);
          expect(bundled.tiers[i].name, source.tiers[i].name);
          expect(bundled.tiers[i].stats, source.tiers[i].stats);
        }
      }
    });
  });

  group('jobArtifactsProvider', () {
    test('分片缺失 → 回退内置常量', () async {
      final data = await _container(null).read(jobArtifactsProvider.future);
      expect(identical(data, kJobArtifacts), isTrue);
    });

    test('分片损坏 → 回退内置常量，不抛异常', () async {
      final data = await _container('{ not json')
          .read(jobArtifactsProvider.future);
      expect(identical(data, kJobArtifacts), isTrue);
    });

    test('分片为空对象 → 回退内置常量（避免整页空白）', () async {
      final data = await _container(_shard({}))
          .read(jobArtifactsProvider.future);
      expect(identical(data, kJobArtifacts), isTrue);
    });

    test('分片有内容 → 使用分片数据', () async {
      final payload = _shard({
        'shaolin': {
          'weapon': '远程武器',
          'tiers': [
            {'lv': 42, 'name': '远程神器', 'intro': 'i', 'extra': 'e'},
          ],
        },
      });
      final data = await _container(payload).read(jobArtifactsProvider.future);

      expect(data.keys, ['shaolin']);
      expect(data['shaolin']!.weapon, '远程武器');
      expect(data['shaolin']!.tiers.single.name, '远程神器');
    });
  });
}
