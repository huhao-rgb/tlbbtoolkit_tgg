import 'dart:convert';

import 'package:tlbbtoolkit/core/content/catalog_cache.dart';

/// 生成与服务端一致形状的清单（sha256 按内容算）。
String manifestJson(Map<String, String> shards, {int schemaVersion = 1}) {
  return jsonEncode({
    'schemaVersion': schemaVersion,
    'dataVersion': '2026.10.23.1',
    'files': [
      for (final e in shards.entries)
        {
          'kind': e.key,
          'schemaVersion': 1,
          'dataVersion': '2026.10.23.1',
          'sha256': sha256Of(e.value),
          'bytes': utf8.encode(e.value).length,
        },
    ],
  });
}
