import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/account_market_fetcher.dart';

/// 构造列表接口响应（`{"code":0,"data":{"goodsList":[...]}}`）。
String _ok(List<Map<String, dynamic>> goods) => jsonEncode({
  'code': 0,
  'msg': '成功',
  'data': {'goodsList': goods, 'total': goods.length},
});

String _good(String sn, {int jobsId = 332, String job = '天山'}) => jsonEncode({
  'goodsSn': sn,
  'bigTitle': '标题 $sn',
  'price': 1000,
  'areaName': '万人大区',
  'serverName': '紫气东来',
  'jobsId': jobsId,
  'jobsName': job,
});

void main() {
  group('fetchSxdsAccountMarket', () {
    test('门派筛选：jobsId 透传到请求参数并解析出 jobsId', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter([
        _ok([jsonDecode(_good('TH1')) as Map<String, dynamic>]),
      ]);
      dio.httpClientAdapter = adapter;

      final r = await fetchSxdsAccountMarket(
        dio: dio,
        pages: 1,
        pageSize: 200,
        query: const AccountMarketQuery(areaId: 1207, jobsId: 332),
      );

      final params = adapter.requests.single.queryParameters;
      expect(params['areaId'], 1207);
      expect(params['jobsId'], 332);
      expect(r.parsed.single.job, '天山');
      expect(r.parsed.single.jobsId, 332);
      dio.close();
    });

    test('未选门派时不带 jobsId 参数', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter([
        _ok([jsonDecode(_good('TH1')) as Map<String, dynamic>]),
      ]);
      dio.httpClientAdapter = adapter;

      await fetchSxdsAccountMarket(dio: dio, pages: 1);
      expect(
        adapter.requests.single.queryParameters.containsKey('jobsId'),
        isFalse,
      );
      dio.close();
    });

    test('AccountMarketQuery.isEmpty：只有 jobsId 也算「有筛选」', () {
      expect(const AccountMarketQuery().isEmpty, isTrue);
      expect(const AccountMarketQuery(jobsId: 332).isEmpty, isFalse);
    });
  });
}

/// 记录请求的适配器（懒生成，避免多页时耗尽）。
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.bodies);

  final List<String> bodies;
  final List<RequestOptions> requests = [];
  int _i = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = bodies[_i < bodies.length ? _i++ : bodies.length - 1];
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
