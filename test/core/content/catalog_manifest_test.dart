import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/content/catalog_manifest.dart';

const _sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, dynamic> _fileJson({
  String kind = 'job.artifacts',
  Object? schemaVersion = 1,
  Object? sha256 = _sha,
  Object? bytes = 12,
}) => {
  'kind': kind,
  'schemaVersion': schemaVersion,
  'dataVersion': '2026.10.23.1',
  'sha256': sha256,
  'bytes': bytes,
};

void main() {
  group('CatalogManifest.fromJson', () {
    test('解析正常清单', () {
      final manifest = CatalogManifest.fromJson({
        'schemaVersion': 2,
        'dataVersion': '2026.10.23.1',
        'files': [_fileJson(), _fileJson(kind: 'pet.beast_spirits')],
      });

      expect(manifest.schemaVersion, 2);
      expect(manifest.dataVersion, '2026.10.23.1');
      expect(
        manifest.files.keys,
        containsAll(['job.artifacts', 'pet.beast_spirits']),
      );
      expect(manifest['job.artifacts']!.sha256, _sha);
      expect(manifest['job.artifacts']!.bytes, 12);
      expect(manifest.isEmpty, isFalse);
    });

    test('坏条目被跳过，不影响其他分片', () {
      final manifest = CatalogManifest.fromJson({
        'schemaVersion': 1,
        'files': [
          _fileJson(),
          _fileJson(kind: 'bad.sha', sha256: 'too-short'),
          _fileJson(kind: 'bad.schema', schemaVersion: '1'),
          _fileJson(kind: 'bad.bytes', bytes: -1),
          'not-a-map',
        ],
      });

      expect(manifest.files.keys, ['job.artifacts']);
    });

    test('根结构不合法时抛 FormatException', () {
      expect(
        () => CatalogManifest.fromJson({'schemaVersion': 0, 'files': []}),
        throwsFormatException,
      );
      expect(
        () => CatalogManifest.fromJson({'schemaVersion': 1}),
        throwsFormatException,
      );
    });

    test('空清单是安全默认值', () {
      expect(CatalogManifest.empty.isEmpty, isTrue);
      expect(CatalogManifest.empty['job.artifacts'], isNull);
    });
  });
}
