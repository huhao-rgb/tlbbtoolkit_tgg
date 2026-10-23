/// 职业神器的数据仓储：从数据目录（catalog）读分片，读不到就用内置常量兜底。
///
/// 为什么保留常量兜底：分片缺失、损坏或远端包结构不兼容时，页面仍要能打开。
/// 常量同时是 [tools/catalog/export_catalog.dart] 的唯一数据源。
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/utils/logger.dart';
import 'package:tlbbtoolkit/features/job/data/job_artifact_parser.dart';
import 'package:tlbbtoolkit/features/job/domain/job_artifact.dart';

part 'job_artifacts_repository.g.dart';

/// 分片标识（与服务端、导出工具保持一致）。
const String jobArtifactsKind = 'job.artifacts';

/// 门派 key → 神器体系。
///
/// 优先级：本地缓存 / 远端覆盖（经 catalog 仓储） → 内置 `assets/catalog/` → 常量。
@riverpod
Future<Map<String, JobArtifact>> jobArtifacts(Ref ref) async {
  final catalog = await ref.watch(catalogRepositoryProvider.future);
  final raw = await catalog.loadShard(jobArtifactsKind);
  if (raw == null) return kJobArtifacts;

  try {
    final parsed = parseJobArtifacts(raw);
    return parsed.isEmpty ? kJobArtifacts : parsed;
  } catch (e, s) {
    Logger.instance.error('Job', 'job.artifacts 分片解析失败，回退内置常量: $e', s);
    return kJobArtifacts;
  }
}
