/// 数据目录（catalog）的清单模型。
///
/// 服务端按**分片**（kind）存放 JSON，客户端只依赖这里的元信息做
/// 「要不要更新」与「内容是否完整」两件事，不关心具体业务字段。
///
/// 与服务端约定见 `server/cloudbase/README.md`「数据目录」一节。
library;

import 'package:flutter/foundation.dart';

/// 一个分片的元信息。
@immutable
class CatalogFile {
  const CatalogFile({
    required this.kind,
    required this.schemaVersion,
    required this.dataVersion,
    required this.sha256,
    required this.bytes,
  });

  /// 分片标识，如 `job.artifacts`。
  final String kind;

  /// 数据结构版本：客户端据此判断能否解析。
  final int schemaVersion;

  /// 内容版本：只用于展示与排查，不参与比较。
  final String dataVersion;

  /// 分片原文的 sha256（小写十六进制）。
  final String sha256;

  /// 原文的 UTF-8 字节数。
  final int bytes;

  /// 解析单条元信息；字段不合法时返回 null（对外部数据保持容错）。
  static CatalogFile? tryParse(Object? json) {
    if (json is! Map) return null;
    final kind = json['kind'];
    final schemaVersion = json['schemaVersion'];
    final dataVersion = json['dataVersion'];
    final sha256 = json['sha256'];
    final bytes = json['bytes'];
    if (kind is! String || kind.isEmpty) return null;
    if (schemaVersion is! int || schemaVersion < 1) return null;
    if (dataVersion is! String) return null;
    if (sha256 is! String || sha256.length != 64) return null;
    if (bytes is! int || bytes < 0) return null;
    return CatalogFile(
      kind: kind,
      schemaVersion: schemaVersion,
      dataVersion: dataVersion,
      sha256: sha256,
      bytes: bytes,
    );
  }
}

/// 一份清单：`{schemaVersion, dataVersion, files: [...]}`。
@immutable
class CatalogManifest {
  const CatalogManifest({
    required this.schemaVersion,
    required this.files,
    this.dataVersion = '',
  });

  /// 空清单：没有任何内置或远端数据时的安全默认值。
  static const CatalogManifest empty = CatalogManifest(
    schemaVersion: 1,
    files: <String, CatalogFile>{},
  );

  final int schemaVersion;

  /// 各分片的汇总内容版本（服务端取所有分片里的最大值）。
  final String dataVersion;

  final Map<String, CatalogFile> files;

  bool get isEmpty => files.isEmpty;

  CatalogFile? operator [](String kind) => files[kind];

  /// 解析清单；结构不合法时抛 [FormatException]（由调用方决定降级策略）。
  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1) {
      throw const FormatException('manifest.schemaVersion 必须是 >= 1 的整数');
    }
    final rawFiles = json['files'];
    if (rawFiles is! List) {
      throw const FormatException('manifest.files 必须是数组');
    }

    final files = <String, CatalogFile>{};
    for (final item in rawFiles) {
      final file = CatalogFile.tryParse(item);
      // 跳过坏条目而不是整体失败：一条坏数据不该让所有分片不可用
      if (file != null) files[file.kind] = file;
    }

    final dataVersion = json['dataVersion'];
    return CatalogManifest(
      schemaVersion: schemaVersion,
      dataVersion: dataVersion is String ? dataVersion : '',
      files: files,
    );
  }
}
