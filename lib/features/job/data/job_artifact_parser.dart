/// `job.artifacts` 分片 → 领域模型。
///
/// 分片由 `tools/catalog/export_catalog.dart` 生成，结构：
/// ```
/// { "schemaVersion": 1, "dataVersion": "…", "kind": "job.artifacts",
///   "items": { "shaolin": { "weapon": "枪棒/刀斧", "tiers": [ … ] } } }
/// ```
///
/// 解析策略：**跳过坏条目而不是整体失败** —— 一条数据写错不该让整页打不开。
library;

import 'dart:convert';

import 'package:tlbbtoolkit/features/job/domain/job_artifact.dart';

Map<String, JobArtifact> parseJobArtifacts(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('job.artifacts 分片顶层必须是对象');
  }
  final items = decoded['items'];
  if (items is! Map) {
    throw const FormatException('job.artifacts.items 必须是对象');
  }

  final result = <String, JobArtifact>{};
  for (final entry in items.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! Map) continue;

    final weapon = value['weapon'];
    final tiers = value['tiers'];
    if (weapon is! String || tiers is! List) continue;

    final parsedTiers = <JobArtifactTier>[];
    for (final item in tiers) {
      final tier = _parseTier(item);
      if (tier != null) parsedTiers.add(tier);
    }
    if (parsedTiers.isEmpty) continue;

    result[key] = JobArtifact(weapon: weapon, tiers: parsedTiers);
  }
  return result;
}

JobArtifactTier? _parseTier(Object? json) {
  if (json is! Map) return null;
  final lv = json['lv'];
  final name = json['name'];
  final intro = json['intro'];
  final extra = json['extra'];
  if (lv is! int || name is! String || intro is! String || extra is! String) {
    return null;
  }
  return JobArtifactTier(
    lv: lv,
    name: name,
    intro: intro,
    stats: _stringList(json['stats']),
    extra: extra,
    how: _stringList(json['how']),
  );
}

List<String> _stringList(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is String) item,
];
