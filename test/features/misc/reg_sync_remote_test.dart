import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_disabled.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_remote.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

const String _syncId = '0123456789abcdef0123456789abcdef';

/// 可编程的 dio 适配器：按请求返回指定响应，并记录请求（校验 query / body）。
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

({Dio dio, _StubAdapter adapter}) _dioWith(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final adapter = _StubAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://sync.example.com'))
    ..httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

void main() {
  group('fetch', () {
    test('200 → RegRemoteSnapshot，并按 query 传 code', () async {
      final t = _dioWith((_) async => _json(200, {'rev': 3, 'blob': 'cipher'}));
      final gw = RegSyncGatewayRemote(t.dio);

      final snap = await gw.fetch(_syncId);
      expect(snap, isNotNull);
      expect(snap!.rev, 3);
      expect(snap.blob, 'cipher');
      expect(t.adapter.last.uri.path, '/reg');
      expect(t.adapter.last.uri.queryParameters['code'], _syncId);
      expect(t.adapter.last.method, 'GET');
    });

    test('404 → null（表示云端还没有记录，不是错误）', () async {
      final t = _dioWith((_) async => _json(404, {'error': 'not_found'}));
      expect(await RegSyncGatewayRemote(t.dio).fetch(_syncId), isNull);
    });

    test('结构不正确 → 不可用（不抛裸解析异常）', () async {
      final t = _dioWith((_) async => _json(200, {'rev': 'x'}));
      await expectLater(
        RegSyncGatewayRemote(t.dio).fetch(_syncId),
        throwsA(isA<RegSyncUnavailableException>()),
      );
    });

    test('content-type 非 JSON（拿到字符串）也能解析', () async {
      final t = _dioWith(
        (_) async => ResponseBody.fromString(
          '{"rev":1,"blob":"b"}',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/plain'],
          },
        ),
      );
      final snap = await RegSyncGatewayRemote(t.dio).fetch(_syncId);
      expect(snap!.rev, 1);
      expect(snap.blob, 'b');
    });

    test('5xx → 不可用（不能被当成冲突）', () async {
      final t = _dioWith((_) async => _json(500, {'error': 'boom'}));
      await expectLater(
        RegSyncGatewayRemote(t.dio).fetch(_syncId),
        throwsA(isA<RegSyncUnavailableException>()),
      );
    });

    test('连接失败 → 不可用', () async {
      final t = _dioWith(
        (o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        RegSyncGatewayRemote(t.dio).fetch(_syncId),
        throwsA(
          isA<RegSyncUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('无法连接'),
          ),
        ),
      );
    });

    test('超时 → 不可用', () async {
      final t = _dioWith(
        (o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      await expectLater(
        RegSyncGatewayRemote(t.dio).fetch(_syncId),
        throwsA(
          isA<RegSyncUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('超时'),
          ),
        ),
      );
    });
  });

  group('push', () {
    test('200 → 返回新 rev；请求体为 {rev, blob}', () async {
      final t = _dioWith((_) async => _json(200, {'rev': 7}));
      final gw = RegSyncGatewayRemote(t.dio);

      final rev = await gw.push(
        syncId: _syncId,
        expectedRev: 6,
        blob: 'cipher',
      );
      expect(rev, 7);
      expect(t.adapter.last.method, 'PUT');
      expect(t.adapter.last.uri.queryParameters['code'], _syncId);
      expect(t.adapter.last.data, {'rev': 6, 'blob': 'cipher'});
    });

    test('409 → 冲突，取回服务端当前 rev', () async {
      final t = _dioWith(
        (_) async => _json(409, {'error': 'conflict', 'rev': 9}),
      );
      await expectLater(
        RegSyncGatewayRemote(t.dio)
            .push(syncId: _syncId, expectedRev: 6, blob: 'cipher'),
        throwsA(
          isA<RegSyncConflictException>()
              .having((e) => e.expectedRev, 'expectedRev', 6)
              .having((e) => e.actualRev, 'actualRev', 9),
        ),
      );
    });

    test('409 未带 rev → 冲突，actualRev 记为 -1（未知）', () async {
      final t = _dioWith((_) async => _json(409, {}));
      await expectLater(
        RegSyncGatewayRemote(t.dio)
            .push(syncId: _syncId, expectedRev: 1, blob: 'c'),
        throwsA(
          isA<RegSyncConflictException>().having(
            (e) => e.actualRev,
            'actualRev',
            -1,
          ),
        ),
      );
    });

    test('创建成功但缺 rev → 不可用（避免把 0 当成有效版本）', () async {
      final t = _dioWith((_) async => _json(200, {'ok': true}));
      await expectLater(
        RegSyncGatewayRemote(t.dio)
            .push(syncId: _syncId, expectedRev: 0, blob: 'c'),
        throwsA(isA<RegSyncUnavailableException>()),
      );
    });

    test('500 → 不可用', () async {
      final t = _dioWith((_) async => _json(500, {}));
      await expectLater(
        RegSyncGatewayRemote(t.dio)
            .push(syncId: _syncId, expectedRev: 0, blob: 'c'),
        throwsA(isA<RegSyncUnavailableException>()),
      );
    });
  });

  group('remove', () {
    for (final code in [200, 204, 404]) {
      test('$code → 成功（幂等删除）', () async {
        final t = _dioWith((_) async => _json(code, {'ok': true}));
        await RegSyncGatewayRemote(t.dio).remove(_syncId);
        expect(t.adapter.last.method, 'DELETE');
      });
    }

    test('500 → 不可用', () async {
      final t = _dioWith((_) async => _json(500, {}));
      await expectLater(
        RegSyncGatewayRemote(t.dio).remove(_syncId),
        throwsA(isA<RegSyncUnavailableException>()),
      );
    });
  });

  test('未配置云同步的占位网关：一律不可用，绝不假装成功', () async {
    const gw = RegSyncGatewayDisabled();
    await expectLater(
      gw.fetch(_syncId),
      throwsA(
        isA<RegSyncUnavailableException>().having(
          (e) => e.message,
          'message',
          contains('未配置'),
        ),
      ),
    );
    await expectLater(
      gw.push(syncId: _syncId, expectedRev: 0, blob: 'c'),
      throwsA(isA<RegSyncUnavailableException>()),
    );
    await expectLater(
      gw.remove(_syncId),
      throwsA(isA<RegSyncUnavailableException>()),
    );
  });
}
