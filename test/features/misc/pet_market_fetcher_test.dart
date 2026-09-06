import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/pet_market_fetcher.dart';
import 'package:tlbbtoolkit/features/misc/domain/pet_market.dart';

/// 构造真实接口 JSON 响应（`{"code":0,"data":{"goodsList":[...]}}`）。
String _apiOk(List<Map<String, dynamic>> goods, {int? total}) {
  return jsonEncode({
    'code': 0,
    'msg': '成功',
    'data': {
      'curDistId': 110,
      'goodsList': goods,
      'total': total ?? goods.length,
    },
  });
}

/// 构造真实接口失败响应（如签名缺失）。
String _apiFail(String msg) => jsonEncode({'code': 1, 'msg': msg});

void main() {
  group('fetchSxdsMarket（真实 JSON API / mock Dio）', () {
    test('成功：多页 JSON 返回 goodsList 并映射为 PetListing', () async {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      // 第 1 页给满 200 条（触发继续翻页），第 2 页不满 → 到底停止。
      final page1 = List<Map<String, dynamic>>.generate(200, (i) {
        if (i == 0) {
          return {
            'bigTitle': '50灵 4500资质 ',
            'price': 2200,
            'areaName': '万人大区',
            'serverName': '紫气东来',
            'baobaoLevel': '89',
            'packId': 53,
            'packName': '85级',
            'lingxingName': '10',
            'wuxingName': '10',
            'goodsSn': 'BB260806221244059074',
            'viewNum': 3346,
            'goodsTags': '50灵',
            'thumbnail': 'img/110/nocs/2026/09/02/1788342889916',
            'id': 14113480,
          };
        }
        return {
          'bigTitle': '普通宝宝$i',
          'price': 100 + i,
          'areaName': '原始一区',
          'serverName': '故人归',
          'goodsSn': 'BBA${100000 + i}',
          'id': 200000 + i,
        };
      });
      dio.httpClientAdapter = _FakeAdapter([
        _apiOk(page1),
        _apiOk([
          {
            'bigTitle': '88谨慎顶变蓝魔4200+妖魔',
            'price': '1799.00',
            'areaName': '原始一区',
            'serverName': '少年游',
            'baobaoLevel': '98',
            'packId': 53,
            'packName': '85级',
            'lingxingName': '10',
            'wuxingName': '10',
            'goodsSn': 'BB26072921353905880269',
            'viewNum': 1555,
            'thumbnail': 'https://cdn.example.com/img/x.png',
            'id': 10936333,
          },
        ]),
      ]);

      final result = await fetchSxdsMarket(dio: dio, pages: 2, pageSize: 200);

      expect(result.raw, 201);
      expect(result.parsed, hasLength(201));
      expect(result.parsed[0].title, '50灵 4500资质');
      expect(result.parsed[0].price, 2200);
      expect(result.parsed[0].area, '万人大区');
      expect(result.parsed[0].server, '紫气东来');
      expect(result.parsed[0].lv, 89);
      expect(result.parsed[0].carry, 85);
      expect(result.parsed[0].carryLevel, 85);
      // 权威档位：packId 53 → 85级
      expect(result.parsed[0].packId, 53);
      expect(result.parsed[0].packName, '85级');
      expect(result.parsed[0].band, PetCarryBand.p85);
      expect(result.parsed[0].carryText, '85级');
      expect(result.parsed[0].ling, '10');
      expect(result.parsed[0].wu, '10');
      expect(result.parsed[0].sn, 'BB260806221244059074');
      expect(result.parsed[0].views, 3346);
      expect(result.parsed[0].apt, 4500);
      // 图片：thumbnail 相对路径 → OSS 完整 URL
      expect(
        result.parsed[0].img,
        'https://oss.sxds.com/img/110/nocs/2026/09/02/1788342889916',
      );
      // 末条来自第二页：从标题启发式还原 ch/ding/apt；绝对 URL 图原样保留。
      final last = result.parsed.last;
      expect(last.ch, '谨慎');
      expect(last.ding, isTrue);
      expect(last.apt, 4200);
      expect(last.img, 'https://cdn.example.com/img/x.png');
      dio.close();
    });

    test('「其他等级」档（packId 56）正确归档且不回退珍兽等级', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter([
        _apiOk([
          {
            'bigTitle': '稀有白猴一只4级大智若愚',
            'price': 9000,
            'areaName': '原始一区',
            'serverName': '少年游',
            'baobaoLevel': '124',
            'packId': 56,
            'packName': '其他等级',
            'goodsSn': 'BBOTHER01',
            'viewNum': 42,
            'id': 99990001,
          },
        ]),
      ]);

      final result = await fetchSxdsMarket(dio: dio, pages: 1, pageSize: 200);
      expect(result.parsed, hasLength(1));
      final p = result.parsed.single;
      expect(p.packId, 56);
      expect(p.packName, '其他等级');
      expect(p.band, PetCarryBand.other);
      expect(p.carryText, '其他等级');
      // carry 无数字；lv 为珍兽当前等级（124），但展示/归档不受其影响。
      expect(p.carry, isNull);
      expect(p.lv, 124);
      dio.close();
    });

    test('签名头已随请求携带（timestamp + visitauth）', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter([
        _apiOk([
          {'bigTitle': '测试宝宝', 'price': 100, 'goodsSn': 'BBX'},
        ]),
      ]);
      dio.httpClientAdapter = adapter;

      await fetchSxdsMarket(dio: dio, pages: 1, pageSize: 200);

      expect(adapter.requests, hasLength(1));
      final headers = adapter.requests.first.headers;
      expect(headers['timestamp'], isNotNull);
      expect(headers['visitauth'], isNotNull);
      expect(headers['visitauth'], isNotEmpty);
      expect(headers['Referer'], 'https://www.sxds.com/wares/');
      final params = adapter.requests.first.queryParameters;
      expect(params['gameId'], 74);
      expect(params['goodsTypeId'], 25);
      expect(params['pages'], 1);
      dio.close();
    });

    test('筛选条件透传：areaId/serverId/packId 加入请求参数', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter([
        _apiOk([
          {'bigTitle': 'A', 'price': 100, 'goodsSn': 'S1'},
        ]),
      ]);
      dio.httpClientAdapter = adapter;

      await fetchSxdsMarket(
        dio: dio,
        pages: 1,
        pageSize: 200,
        query: const PetMarketQuery(
          areaId: 1207,
          serverId: '22311,9328',
          packId: 52,
        ),
      );

      expect(adapter.requests, hasLength(1));
      final params = adapter.requests.first.queryParameters;
      expect(params['areaId'], 1207);
      expect(params['serverId'], '22311,9328');
      expect(params['packId'], 52);
      dio.close();
    });

    test('有筛选时持续翻页直到不足一页（拉全）', () async {
      final dio = Dio();
      // 三页：满 2 / 满 2 / 不足 → 到底。
      final page = <Map<String, dynamic>>[
        for (var i = 0; i < 200; i++)
          {'bigTitle': 'P1#$i', 'price': 100 + i, 'id': 100000 + i},
      ];
      final page2 = <Map<String, dynamic>>[
        for (var i = 0; i < 200; i++)
          {'bigTitle': 'P2#$i', 'price': 100 + i, 'id': 200000 + i},
      ];
      final page3 = <Map<String, dynamic>>[
        for (var i = 0; i < 13; i++)
          {'bigTitle': 'P3#$i', 'price': 100 + i, 'id': 300000 + i},
      ];
      final adapter = _RecordingAdapter([
        _apiOk(page),
        _apiOk(page2),
        _apiOk(page3),
      ]);
      dio.httpClientAdapter = adapter;

      final r = await fetchSxdsMarket(
        dio: dio,
        pages: 1, // 无筛选时会停在这里；但带筛选应忽略 pages 继续翻。
        pageSize: 200,
        query: const PetMarketQuery(serverId: '22311'),
      );

      expect(adapter.requests, hasLength(3)); // 拉满 3 页到不足为止
      expect(r.raw, 413);
      expect(r.parsed, hasLength(413));
      dio.close();
    });

    test('接口返回失败（code!=0）→ 抛含 msg 的异常', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter([_apiFail('访问权限失败')]);

      await expectLater(
        fetchSxdsMarket(dio: dio, pages: 1),
        throwsA(
          isA<PetMarketFetchException>().having(
            (e) => e.message,
            'message',
            contains('访问权限失败'),
          ),
        ),
      );
      dio.close();
    });

    test('非 JSON（HTML/验证页）→ 抛「接口返回非 JSON」', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter([
        '<html><body>verify challenge</body></html>',
      ]);

      await expectLater(
        fetchSxdsMarket(dio: dio, pages: 1),
        throwsA(
          isA<PetMarketFetchException>().having(
            (e) => e.message,
            'message',
            contains('非 JSON'),
          ),
        ),
      );
      dio.close();
    });

    test('JSON 但无 goodsList → 抛「无商品列表」', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter([
        jsonEncode({
          'code': 0,
          'data': {'total': 0},
        }),
      ]);

      await expectLater(
        fetchSxdsMarket(dio: dio, pages: 1),
        throwsA(
          isA<PetMarketFetchException>().having(
            (e) => e.message,
            'message',
            contains('无商品列表'),
          ),
        ),
      );
      dio.close();
    });

    test('多页无新商品（全空页）→ 抛「未获取到商品数据」', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter([_apiOk([]), _apiOk([])]);

      await expectLater(
        fetchSxdsMarket(dio: dio, pages: 2),
        throwsA(
          isA<PetMarketFetchException>().having(
            (e) => e.message,
            'message',
            contains('未获取到商品数据'),
          ),
        ),
      );
      dio.close();
    });

    test('网络异常 → DioException 包装为 PetMarketFetchException', () async {
      final dio = Dio();
      dio.httpClientAdapter = _ThrowingAdapter();

      await expectLater(
        fetchSxdsMarket(dio: dio, pages: 1),
        throwsA(isA<PetMarketFetchException>()),
      );
      dio.close();
    });
  });
}

/// 内存 HTTP 适配器：按序返回给定 JSON 响应。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.pages);

  final List<String> pages;
  int _i = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = pages[_i < pages.length ? _i++ : pages.length - 1];
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

/// 记录请求的适配器。
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.pages);

  final List<String> pages;
  final List<RequestOptions> requests = [];
  int _i = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = pages[_i < pages.length ? _i++ : pages.length - 1];
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

/// 网络异常适配器。
class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'Connection refused',
    );
  }

  @override
  void close({bool force = false}) {}
}
