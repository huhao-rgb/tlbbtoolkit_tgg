import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';
import 'package:tlbbtoolkit/core/content/catalog_manifest.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';

/// 内置基线（`assets/catalog/`）由 `tools/catalog/export_catalog.dart` 生成。
///
/// 这条测试防止「改了 domain 常量却忘记重新导出」：
/// 只要分片与 manifest 的哈希不一致就会红。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('内置 manifest 可解析且分片齐全', () async {
    final raw = await rootBundle.loadString(
      CatalogRepository.bundledManifestPath,
    );
    final manifest = CatalogManifest.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    expect(manifest.schemaVersion, 1);
    expect(manifest.files, isNotEmpty);
    // 每片都必须有 schemaVersion / dataVersion / sha256 / bytes
    for (final file in manifest.files.values) {
      expect(file.schemaVersion, greaterThanOrEqualTo(1), reason: file.kind);
      expect(file.dataVersion, isNotEmpty, reason: file.kind);
      expect(file.sha256, hasLength(64), reason: file.kind);
      expect(file.bytes, greaterThan(0), reason: file.kind);
    }
  });

  test('每个内置分片的 sha256 / 字节数与 manifest 一致', () async {
    final raw = await rootBundle.loadString(
      CatalogRepository.bundledManifestPath,
    );
    final manifest = CatalogManifest.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    for (final file in manifest.files.values) {
      final body = await rootBundle.loadString(
        CatalogRepository.bundledShardPath(file.kind),
      );
      expect(sha256Of(body), file.sha256, reason: file.kind);
      expect(utf8.encode(body).length, file.bytes, reason: file.kind);
    }
  });
}
