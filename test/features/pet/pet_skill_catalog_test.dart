import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/features/pet/data/pet_catalog.dart';
import 'package:tlbbtoolkit/features/pet/domain/pet_prob.dart';

import '../../core/content/fake_asset_bundle.dart';
import '../../core/content/fake_catalog_storage.dart';

/// 用真实的内置分片喂给仓储，验证「pet.skills → PetSkill / PetChar」解析链路。
class _StubCatalog extends CatalogRepository {
  _StubCatalog(this.payload)
    : super(
        cache: CatalogCache(FakeCatalogStorage()),
        bundle: FakeAssetBundle({}),
      );

  final String? payload;

  @override
  Future<String?> loadShard(String kind) async =>
      kind == petSkillsKind ? payload : null;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('内置 pet.skills 分片解析后与 domain 常量完全一致', () async {
    final raw = await rootBundle.loadString(
      CatalogRepository.bundledShardPath(petSkillsKind),
    );
    final catalog = await _container(raw).read(petSkillCatalogProvider.future);

    // 技能：数量 / 名称顺序 / 系别 / 基础概率 / 判定 / 图标都与常量一致
    expect(catalog.skills.length, kPetSkills.length);
    for (var i = 0; i < kPetSkills.length; i++) {
      final parsed = catalog.skills[i];
      final expected = kPetSkills[i];
      expect(parsed.name, expected.name, reason: '第 $i 个技能名');
      expect(parsed.family, expected.family, reason: '${expected.name} 系别');
      expect(parsed.base, expected.base, reason: '${expected.name} 基础概率');
      expect(parsed.judge, expected.judge, reason: '${expected.name} 判定');
      expect(parsed.icon, expected.icon, reason: '${expected.name} 图标');
      expect(parsed.desc, expected.desc, reason: '${expected.name} 描述');
      expect(parsed.fx, expected.fx, reason: '${expected.name} 详情');
    }

    // 性格：只有五种（无通用 / 内敛），五系系数逐格一致
    expect(
      catalog.chars.map((c) => c.name).toList(),
      kPetChars.map((c) => c.name).toList(),
    );
    expect(catalog.chars.length, 5);
    expect(catalog.chars.any((c) => c.name == '通用'), isFalse);
    expect(catalog.chars.any((c) => c.name == '内敛'), isFalse);
    for (var i = 0; i < kPetChars.length; i++) {
      for (final family in PetSkillFamily.values) {
        expect(
          catalog.chars[i].factorFor(family),
          kPetChars[i].factorFor(family),
          reason: '${kPetChars[i].name} × ${family.label} 系数',
        );
      }
    }
  });

  test('旧版分片（cat / atk·st·sup）整体回退内置常量', () async {
    final raw = jsonEncode({
      'schemaVersion': 1,
      'dataVersion': '2026.10.20.legacy',
      'kind': petSkillsKind,
      'items': {
        'skills': [
          {
            'name': '猛击',
            'desc': '',
            'cat': 'atk',
            'tag': '自动攻击',
            'tagColor': 'gold',
            'base': 20,
            'judge': '攻击判定',
            'icon': 'sk-mengji',
            'fx': '旧文案',
          },
        ],
        'chars': [
          {'key': 'yongmeng', 'name': '勇猛', 'atk': 1.3, 'st': 0.8, 'sup': 0.9},
        ],
      },
    });
    final catalog = await _container(raw).read(petSkillCatalogProvider.future);
    // 缺 family / factors → 视为旧分片，整体回退常量（不能把系别错读成物攻）
    expect(catalog.skills.length, kPetSkills.length);
    expect(catalog.skills.first.name, '反击');
    expect(catalog.chars.length, kPetChars.length);
    expect(catalog.chars.length, 5);
    expect(catalog.chars.any((c) => c.name == '通用'), isFalse);
    expect(catalog.chars.any((c) => c.name == '内敛'), isFalse);
  });

  test('分片缺 factors 时按 1 兜底，不整体失效', () async {
    final raw = jsonEncode({
      'schemaVersion': 1,
      'dataVersion': '2026.10.26.test',
      'kind': petSkillsKind,
      'items': {
        'skills': [
          {
            'name': '反击',
            'desc': '',
            'family': 'revenge',
            'base': 20,
            'judge': '受击判定',
            'icon': 'sk-fanji',
            'fx': '测试',
          },
        ],
        'chars': [
          {
            'key': 'danxiao',
            'name': '胆小',
            'factors': {'magic': 2},
          },
        ],
      },
    });
    final catalog = await _container(raw).read(petSkillCatalogProvider.future);
    final ch = catalog.chars.single;
    expect(ch.factorFor(PetSkillFamily.magic), 2);
    expect(ch.factorFor(PetSkillFamily.revenge), 1);
    expect(petProbOf(catalog.skills.single, ch), 20); // 20 × 1（缺省兜底）
  });
}
