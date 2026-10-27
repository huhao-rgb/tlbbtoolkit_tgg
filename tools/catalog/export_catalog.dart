/// 把 `domain/` 里的静态数据导出成数据目录（catalog）分片。
///
/// 为什么用 `flutter test` 运行而不是 `dart run`：
/// 领域文件（如 `job_artifact.dart`）为了 `@immutable` 引入了
/// `package:flutter/foundation.dart`，普通 Dart VM 里没有 `dart:ui`，编译不过。
/// Flutter 测试环境提供了 `dart:ui`，因此用一次性的 test 承载导出逻辑。
///
/// 用法：
///   fvm flutter test tools/catalog/export_catalog.dart
///
/// 产物：`assets/catalog/{kind}.json`，格式：
///   { "schemaVersion": 1, "dataVersion": "日期.内容哈希前 8 位",
///     "kind": "job.artifacts", "items": ... }
///
/// 新增分片时：在 [_shards] 里加一项即可，其余（版本号、落盘）自动处理。
/// 枚举一律导出 `.name`（如 `shen` / `gold`），客户端按同一字符串还原。
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/job/domain/job_artifact.dart';
import 'package:tlbbtoolkit/features/job/domain/job_point.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect_info.dart';
import 'package:tlbbtoolkit/features/job/domain/job_skill.dart';
import 'package:tlbbtoolkit/features/job/domain/job_wudao.dart';
import 'package:tlbbtoolkit/features/pet/domain/beast_soul.dart';
import 'package:tlbbtoolkit/features/pet/domain/beast_spirit.dart';
import 'package:tlbbtoolkit/features/pet/domain/pet_prob.dart';
import 'package:tlbbtoolkit/features/pet/domain/pet_suit.dart';

/// 客户端能解析的结构版本（与服务端 `handler.js` 的 SCHEMA_VERSION 对齐）。
const int _schemaVersion = 1;

const String _outDir = 'assets/catalog';

/// 统一的分片内容版本：`YYYY.MM.DD.<内容哈希前 8 位>`。
///
/// 用「日期 + 哈希」而不是手工序号：内容一变版本必然变，且能一眼看出是哪天的数据。
/// 真正的更新判断仍走 sha256，这里只用于展示与排查。
String _dataVersionOf(String itemsJson) {
  final now = DateTime.now();
  final date =
      '${now.year.toString().padLeft(4, '0')}.'
      '${now.month.toString().padLeft(2, '0')}.'
      '${now.day.toString().padLeft(2, '0')}';
  final digest = sha256.convert(utf8.encode(itemsJson)).toString();
  return '$date.${digest.substring(0, 8)}';
}

/// kind → items（只包含业务内容，版本字段由 [_writeShard] 补齐）。
Map<String, Object?> _shards() => {
  'job.sects': [
    for (final sect in kJobSects)
      {
        'key': sect.key,
        'name': sect.name,
        'type': sect.type,
        'colorValue': sect.colorValue,
      },
  ],
  'job.artifacts': {
    for (final entry in kJobArtifacts.entries)
      entry.key: {
        'weapon': entry.value.weapon,
        'tiers': [
          for (final tier in entry.value.tiers)
            {
              'lv': tier.lv,
              'name': tier.name,
              'intro': tier.intro,
              'stats': tier.stats,
              'extra': tier.extra,
              'how': tier.how,
            },
        ],
      },
  },
  'job.skills': {
    'minds': {
      for (final entry in kJobMinds.entries)
        entry.key: [
          for (final mind in entry.value)
            {'name': mind.name, 'desc': mind.desc},
        ],
    },
    'skills': {
      for (final entry in kJobSkills.entries)
        entry.key: [
          for (final skill in entry.value)
            {
              'name': skill.name,
              'type': skill.type,
              'cd': skill.cd,
              'desc': skill.desc,
              'mind': skill.mind,
            },
        ],
    },
  },
  'job.sect_info': {
    for (final entry in kJobSectInfo.entries)
      entry.key: {
        'intro': entry.value.intro,
        'atk': entry.value.atk,
        'atkColor': entry.value.atkColor,
        'main': entry.value.main,
        'atype': entry.value.atype,
        'traits': [
          for (final trait in entry.value.traits)
            {'label': trait.label, 'value': trait.value},
        ],
        'suit': entry.value.suit,
        'bg': entry.value.bg,
        'life': [
          for (final life in entry.value.life)
            {'name': life.name, 'desc': life.desc, 'at': life.at},
        ],
      },
  },
  'job.wudao': {
    'tierNames': kWudaoTierCn,
    'schools': {
      for (final entry in kWudao.entries)
        entry.key: [
          for (final school in entry.value)
            {
              'name': school.name,
              'passive': {
                'name': school.passive.name,
                'desc': school.passive.desc,
                'icon': school.passive.icon,
              },
              'layers': [
                for (final layer in school.layers)
                  {
                    'nodes': [
                      for (final node in layer.nodes)
                        {
                          'name': node.name,
                          'effect': node.effect,
                          'icon': node.icon,
                        },
                    ],
                  },
              ],
            },
        ],
    },
  },
  'job.point': {
    'lvMin': kPointLvMin,
    'lvMax': kPointLvMax,
    'attrs': [
      for (final attr in kJobAttrs) {'key': attr.key, 'label': attr.label},
    ],
    'weights': kJobWeights,
    'growthFields': [
      for (final field in kJobGrowthFields)
        {'key': field.key, 'label': field.label},
    ],
    'growth': {
      for (final sect in kJobGrowth.entries)
        sect.key: {
          for (final field in sect.value.entries)
            field.key: {
              'value': field.value.value,
              'approx': field.value.approx,
            },
        },
    },
  },
  'pet.beast_spirits': {
    'tierSteps': [
      for (final step in kBeastTierSteps) {'name': step.name, 'lv': step.lv},
    ],
    'spirits': [
      for (final spirit in kBeastSpirits)
        {
          'id': spirit.id,
          'name': spirit.name,
          'sub': spirit.sub,
          'kind': spirit.kind.name,
          'tiers': [
            for (final tier in spirit.tiers)
              {
                'name': tier.name,
                'lv': tier.lv,
                'dec': tier.dec,
                'effect1': tier.effect1,
                'effect2': tier.effect2,
              },
          ],
        },
    ],
    'introNote': kBeastIndexIntroNote,
    'footNote': kBeastIndexFootNote,
  },
  'pet.beast_souls': [
    for (final soul in kBeastSouls)
      {
        'name': soul.name,
        'type': soul.type.name,
        'cs': {
          'name': soul.cs.name,
          'description': soul.cs.description,
          'iconPath': soul.cs.iconPath,
        },
        'rh': {
          'name': soul.rh.name,
          'iconPath': soul.rh.iconPath,
          'tiers': [
            for (final tier in soul.rh.tiers)
              {'lv': tier.lv, 'description': tier.description},
          ],
        },
      },
  ],
  'pet.suits': {
    'lvKeys': kSuitLvKeys,
    'matName': kSuitMatName,
    'series': [
      for (final series in kPetSuitSeries)
        {
          'name': series.name,
          'lv': series.lv,
          'type': series.type,
          'typeColor': series.typeColor.name,
          'icon': series.icon,
          'personality': series.personality,
          'fullEffect': series.fullEffect,
          'stats': series.stats,
          'collar': series.collar,
        },
    ],
    'slots': [
      for (final slot in kPetSuitSlots)
        {
          'name': slot.name,
          'slot': slot.slot,
          'icon': slot.icon,
          'note': slot.note,
        },
    ],
    'matCost': {
      for (final entry in kSuitMatCost.entries)
        entry.key: {
          'exchange': entry.value.exchange,
          'starUp': entry.value.starUp,
          'salvage': entry.value.salvage,
        },
    },
  },
  'pet.skills': {
    'skills': [
      for (final skill in kPetSkills)
        {
          'name': skill.name,
          'desc': skill.desc,
          'family': skill.family.name,
          'base': skill.base,
          'judge': skill.judge,
          'icon': skill.icon,
          'fx': skill.fx,
        },
    ],
    'chars': [
      for (final char in kPetChars)
        {
          'key': char.key,
          'name': char.name,
          'factors': {
            for (final family in PetSkillFamily.values)
              family.name: char.factorFor(family),
          },
        },
    ],
  },
};

/// 写入单个分片，返回它在 manifest 里的条目。
Map<String, Object?> _writeShard(String kind, Object? items) {
  // items 单独序列化后再算版本，保证「同样内容 → 同样版本号」
  final itemsJson = jsonEncode(items);
  final dataVersion = _dataVersionOf(itemsJson);
  final document = {
    'schemaVersion': _schemaVersion,
    'dataVersion': dataVersion,
    'kind': kind,
    'items': items,
  };
  final raw = '${const JsonEncoder.withIndent('  ').convert(document)}\n';
  final file = File('$_outDir/$kind.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(raw);

  return {
    'kind': kind,
    'schemaVersion': _schemaVersion,
    'dataVersion': dataVersion,
    'sha256': sha256.convert(utf8.encode(raw)).toString(),
    'bytes': utf8.encode(raw).length,
  };
}

/// 内置清单：与远端 manifest 同构，供离线时 `effectiveManifest()` 使用，
/// 也让「分片是否随常量一起更新」可被测试校验。
void _writeManifest(List<Map<String, Object?>> files) {
  final sorted = [...files]
    ..sort((a, b) => (a['kind'] as String).compareTo(b['kind'] as String));
  final dataVersion = sorted.fold<String>(
    '',
    (max, f) => (f['dataVersion'] as String).compareTo(max) > 0
        ? f['dataVersion'] as String
        : max,
  );
  final document = {
    'schemaVersion': _schemaVersion,
    'dataVersion': dataVersion,
    'files': sorted,
  };
  File('$_outDir/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(document)}\n',
  );
}

void main() {
  test('导出数据目录分片到 $_outDir/', () {
    final files = [
      for (final entry in _shards().entries)
        _writeShard(entry.key, entry.value),
    ];
    _writeManifest(files);
  });
}
