/// job 相关分片的解析与提供者。
///
/// 页面用 `ref.watch(xxxProvider).valueOrNull ?? 常量` 的方式取数：
/// 首帧立刻拿到内置常量（不闪 loading），分片读好后自动重建。
/// 为什么不在页面里等 `AppAsyncView`：这些页面的数据是「整页骨架」的一部分，
/// 等异步反而会让首屏出现空档。
library;

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/utils/logger.dart';
import 'package:tlbbtoolkit/features/job/domain/job_sect_info.dart';
import 'package:tlbbtoolkit/features/job/domain/job_skill.dart';
import 'package:tlbbtoolkit/features/job/domain/job_wudao.dart';

part 'job_catalog.g.dart';

const String jobSkillsKind = 'job.skills';
const String jobSectInfoKind = 'job.sect_info';
const String jobWudaoKind = 'job.wudao';

/// 心法 + 技能（按门派分组）。
typedef JobSkillCatalog = ({
  Map<String, List<JobMind>> minds,
  Map<String, List<JobSkill>> skills,
});

/// 武道：重数文案 + 各门派流派。
typedef JobWudaoCatalog = ({
  List<String> tierNames,
  Map<String, List<WudaoSchool>> schools,
});

/// 读分片原文；不可用时返回 null（调用方走内置兜底）。
Future<String?> _loadShard(Ref ref, String kind) async {
  final repository = await ref.watch(catalogRepositoryProvider.future);
  return repository.loadShard(kind);
}

@riverpod
Future<JobSkillCatalog> jobSkillCatalog(Ref ref) async {
  final fallback = (minds: kJobMinds, skills: kJobSkills);
  final raw = await _loadShard(ref, jobSkillsKind);
  if (raw == null) return fallback;
  try {
    return _parseSkills(raw);
  } catch (e, s) {
    Logger.instance.error('Job', '$jobSkillsKind 解析失败，回退常量: $e', s);
    return fallback;
  }
}

@riverpod
Future<Map<String, JobSectInfo>> jobSectInfoCatalog(Ref ref) async {
  final raw = await _loadShard(ref, jobSectInfoKind);
  if (raw == null) return kJobSectInfo;
  try {
    final parsed = _parseSectInfo(raw);
    return parsed.isEmpty ? kJobSectInfo : parsed;
  } catch (e, s) {
    Logger.instance.error('Job', '$jobSectInfoKind 解析失败，回退常量: $e', s);
    return kJobSectInfo;
  }
}

@riverpod
Future<JobWudaoCatalog> jobWudaoCatalog(Ref ref) async {
  final fallback = (tierNames: kWudaoTierCn, schools: kWudao);
  final raw = await _loadShard(ref, jobWudaoKind);
  if (raw == null) return fallback;
  try {
    return _parseWudao(raw);
  } catch (e, s) {
    Logger.instance.error('Job', '$jobWudaoKind 解析失败，回退常量: $e', s);
    return fallback;
  }
}

// ---------------------------------------------------------------------------
// 解析（坏条目跳过，不整体失败）
// ---------------------------------------------------------------------------

Map<String, dynamic> _items(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('分片顶层必须是对象');
  }
  final items = decoded['items'];
  if (items is! Map) throw const FormatException('items 必须是对象');
  return items.cast<String, dynamic>();
}

JobSkillCatalog _parseSkills(String raw) {
  final items = _items(raw);
  final minds = <String, List<JobMind>>{};
  final skills = <String, List<JobSkill>>{};

  final rawMinds = items['minds'];
  if (rawMinds is Map) {
    for (final entry in rawMinds.entries) {
      final list = entry.value;
      if (entry.key is! String || list is! List) continue;
      minds[entry.key as String] = [
        for (final item in list)
          if (item is Map && item['name'] is String && item['desc'] is String)
            JobMind(name: item['name'] as String, desc: item['desc'] as String),
      ];
    }
  }

  final rawSkills = items['skills'];
  if (rawSkills is Map) {
    for (final entry in rawSkills.entries) {
      final list = entry.value;
      if (entry.key is! String || list is! List) continue;
      skills[entry.key as String] = [for (final item in list) ?_skillOf(item)];
    }
  }

  if (skills.isEmpty) throw const FormatException('skills 为空');
  return (minds: minds.isEmpty ? kJobMinds : minds, skills: skills);
}

JobSkill? _skillOf(Object? json) {
  if (json is! Map) return null;
  final name = json['name'];
  final type = json['type'];
  final cd = json['cd'];
  final desc = json['desc'];
  final mind = json['mind'];
  if (name is! String || type is! String || cd is! String) return null;
  if (desc is! String || mind is! int) return null;
  return JobSkill(name: name, type: type, cd: cd, desc: desc, mind: mind);
}

Map<String, JobSectInfo> _parseSectInfo(String raw) {
  final items = _items(raw);
  final result = <String, JobSectInfo>{};
  for (final entry in items.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final info = _sectInfoOf(value);
    if (info != null) result[entry.key] = info;
  }
  return result;
}

JobSectInfo? _sectInfoOf(Map json) {
  final intro = json['intro'];
  final atkColor = json['atkColor'];
  final main = json['main'];
  final atype = json['atype'];
  final suit = json['suit'];
  if (intro is! String || atkColor is! String || main is! String) return null;
  if (atype is! String || suit is! String) return null;

  return JobSectInfo(
    intro: intro,
    atk: _strings(json['atk']),
    atkColor: atkColor,
    main: main,
    atype: atype,
    traits: [
      for (final item in json['traits'] as List? ?? const [])
        if (item is Map && item['label'] is String && item['value'] is String)
          JobTrait(
            label: item['label'] as String,
            value: item['value'] as String,
          ),
    ],
    suit: suit,
    bg: json['bg'] is String ? json['bg'] as String : '',
    life: [
      for (final item in json['life'] as List? ?? const [])
        if (item is Map && item['name'] is String && item['desc'] is String)
          JobLifeSkill(
            name: item['name'] as String,
            desc: item['desc'] as String,
            at: item['at'] is String ? item['at'] as String : null,
          ),
    ],
  );
}

JobWudaoCatalog _parseWudao(String raw) {
  final items = _items(raw);
  final schools = <String, List<WudaoSchool>>{};

  final rawSchools = items['schools'];
  if (rawSchools is Map) {
    for (final entry in rawSchools.entries) {
      final list = entry.value;
      if (entry.key is! String || list is! List) continue;
      final parsed = <WudaoSchool>[];
      for (final item in list) {
        final school = _schoolOf(item);
        if (school != null) parsed.add(school);
      }
      if (parsed.isNotEmpty) schools[entry.key as String] = parsed;
    }
  }
  if (schools.isEmpty) throw const FormatException('schools 为空');

  final tierNames = _strings(items['tierNames']);
  return (
    tierNames: tierNames.isEmpty ? kWudaoTierCn : tierNames,
    schools: schools,
  );
}

WudaoSchool? _schoolOf(Object? json) {
  if (json is! Map) return null;
  final name = json['name'];
  final passive = json['passive'];
  final layers = json['layers'];
  if (name is! String || passive is! Map || layers is! List) return null;

  final passiveName = passive['name'];
  final passiveDesc = passive['desc'];
  if (passiveName is! String || passiveDesc is! String) return null;

  return WudaoSchool(
    name: name,
    passive: WudaoPassive(
      name: passiveName,
      desc: passiveDesc,
      icon: passive['icon'] is String ? passive['icon'] as String : null,
    ),
    layers: [
      for (final layer in layers)
        if (layer is Map)
          WudaoLayer(
            nodes: [
              for (final node in layer['nodes'] as List? ?? const [])
                if (node is Map &&
                    node['name'] is String &&
                    node['effect'] is String)
                  WudaoNode(
                    name: node['name'] as String,
                    effect: node['effect'] as String,
                    icon: node['icon'] is String
                        ? node['icon'] as String
                        : null,
                  ),
            ],
          ),
    ],
  );
}

List<String> _strings(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is String) item,
];
