/// 数据目录的远端数据源（只读：manifest + 分片）。
///
/// 服务端契约见 `server/cloudbase/README.md`：
///   GET {base}/catalog/manifest.json   支持 If-None-Match → 304
///   GET {base}/catalog/{kind}.json
library;

import 'package:dio/dio.dart';

/// 一次 manifest 请求的结果。
class CatalogFetch {
  const CatalogFetch.notModified()
    : notModified = true,
      body = null,
      etag = null;

  const CatalogFetch.ok({required this.body, this.etag}) : notModified = false;

  final bool notModified;

  /// 原文（未做任何重排，sha256 校验依赖这一点）。
  final String? body;

  /// 响应头 ETag（含引号），下次用作 If-None-Match。
  final String? etag;
}

class CatalogRemoteSource {
  CatalogRemoteSource(
    this._dio, {
    required String baseUrl,
    this.pathPrefix = '/catalog',
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl;

  final Dio _dio;
  final String _baseUrl;
  final String pathPrefix;

  String _url(String name) => '$_baseUrl$pathPrefix/$name';

  Options _options({bool conditional = false, String? etag}) => Options(
    responseType: ResponseType.plain,
    // 304 是正常结果，不是错误
    validateStatus: (status) => status == 200 || status == 304,
    headers: {
      if (conditional && etag != null && etag.isNotEmpty) 'If-None-Match': etag,
    },
  );

  Future<CatalogFetch> fetchManifest({String? etag}) async {
    final res = await _dio.get<String>(
      _url('manifest.json'),
      options: _options(conditional: true, etag: etag),
    );
    if (res.statusCode == 304) return const CatalogFetch.notModified();
    final body = res.data;
    if (body == null || body.isEmpty) {
      throw const FormatException('manifest 响应体为空');
    }
    return CatalogFetch.ok(body: body, etag: res.headers.value('etag'));
  }

  Future<String> fetchShard(String kind) async {
    final res = await _dio.get<String>(_url('$kind.json'), options: _options());
    final body = res.data;
    if (body == null) throw FormatException('分片 $kind 响应体为空');
    return body;
  }
}
