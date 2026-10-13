import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

/// [RegSyncGateway] 的 dio 实现（腾讯云开发 CloudBase HTTP 访问服务）。
///
/// 与服务端的契约（服务端只做哑存储，不理解任何业务语义）：
/// ```
/// GET    {path}?code=<syncId>           → 200 {rev, blob} | 404
/// PUT    {path}?code=<syncId>  {rev, blob} → 200 {rev}     | 409 {rev}
/// DELETE {path}?code=<syncId>           → 200 {}
/// ```
///
/// 失败只向领域层映射两类（不把 `DioException` 泄漏给引擎）：
/// - 超时 / 连接失败 / 5xx / 响应结构异常 → [RegSyncUnavailableException]（可重试）
/// - 409 → [RegSyncConflictException]（引擎会重拉 → 合并 → 重试）
///
/// 4xx 用 `validateStatus` 放行后自行分支（404 表示「尚未创建」、409 表示冲突），
/// 这样它们不会先被 dio 包装成异常再解包。
class RegSyncGatewayRemote implements RegSyncGateway {
  RegSyncGatewayRemote(
    this._dio, {
    this.path = '/reg',
    this.timeout = const Duration(seconds: 12),
  });

  final Dio _dio;

  /// 接口路径（需与控制台 HTTP 访问服务配置一致）。
  final String path;

  final Duration timeout;

  Options get _options => Options(
    validateStatus: (status) => status != null && status < 500,
    sendTimeout: timeout,
    receiveTimeout: timeout,
  );

  @override
  Future<RegRemoteSnapshot?> fetch(String syncId) async {
    final res = await _send(
      () => _dio.get<dynamic>(
        path,
        queryParameters: {'code': syncId},
        options: _options,
      ),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw RegSyncUnavailableException('云端返回 ${res.statusCode}');
    }
    final body = _asMap(res.data);
    final rev = _asInt(body?['rev']);
    final blob = body?['blob'];
    if (rev == null || blob is! String) {
      throw const RegSyncUnavailableException('云端响应结构不正确');
    }
    return RegRemoteSnapshot(rev: rev, blob: blob);
  }

  @override
  Future<int> push({
    required String syncId,
    required int expectedRev,
    required String blob,
  }) async {
    final res = await _send(
      () => _dio.put<dynamic>(
        path,
        queryParameters: {'code': syncId},
        data: {'rev': expectedRev, 'blob': blob},
        options: _options,
      ),
    );
    final body = _asMap(res.data);
    if (res.statusCode == 409) {
      // 服务端会带回当前实际 rev；拿不到时用 -1 表示未知
      // （引擎只关心「是冲突」，不看具体数值）。
      throw RegSyncConflictException(
        expectedRev: expectedRev,
        actualRev: _asInt(body?['rev']) ?? -1,
      );
    }
    if (res.statusCode != 200) {
      throw RegSyncUnavailableException('云端返回 ${res.statusCode}');
    }
    final rev = _asInt(body?['rev']);
    if (rev == null) {
      throw const RegSyncUnavailableException('云端未返回新版本号');
    }
    return rev;
  }

  @override
  Future<void> remove(String syncId) async {
    final res = await _send(
      () => _dio.delete<dynamic>(
        path,
        queryParameters: {'code': syncId},
        options: _options,
      ),
    );
    final code = res.statusCode;
    // 记录不存在也算成功（幂等删除）
    if (code == 200 || code == 204 || code == 404) return;
    throw RegSyncUnavailableException('云端返回 $code');
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw RegSyncUnavailableException(_describe(e));
    }
  }

  static String _describe(DioException e) {
    final code = e.response?.statusCode;
    if (code != null) return '云端错误（HTTP $code）';
    final why = _why(e.error);
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '云端请求超时$why',
      DioExceptionType.connectionError => '无法连接云端$why',
      _ => '云端请求失败（${e.type.name}）$why',
    };
  }

  /// 把底层原因附在文案后面（DNS 解析失败 / 连接被拒 / TLS 握手失败…）。
  ///
  /// 只说「无法连接云端」无法区分是哪一种，而真机排查恰恰只差这一条信息
  /// （真机上没有断点可看）。该文案**只进日志**，不展示给用户；
  /// 内容是公开域名与系统错误，不含任何密钥。
  static String _why(Object? error) {
    if (error == null) return '';
    var text = '$error'.replaceAll('\n', ' ').trim();
    if (text.length > 160) text = '${text.substring(0, 160)}…';
    return '（${error.runtimeType}: $text）';
  }

  /// 兼容 dio 已解析的 JSON 与「content-type 不对导致拿到字符串」两种情况。
  static Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        return decoded is Map<String, dynamic> ? decoded : null;
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static int? _asInt(Object? value) => switch (value) {
    int _ => value,
    num _ => value.toInt(),
    String _ => int.tryParse(value),
    _ => null,
  };
}
