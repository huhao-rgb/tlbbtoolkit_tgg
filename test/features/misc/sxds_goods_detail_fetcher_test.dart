import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/sxds_goods_detail_fetcher.dart';

/// 详情接口响应（结构与线上 `/api/goods/goodsInfo` 一致）。
String _detailOk({
  List<Map<String, dynamic>>? images,
  String? thumbnail,
  Map<String, dynamic> extra = const {},
}) {
  return jsonEncode({
    'code': 0,
    'msg': '成功',
    'data': {
      'id': 16389931,
      'goodsSn': 'TH356361',
      'goodsTypeName': '游戏账号',
      'bigTitle': '工作调动没时间玩了',
      'price': 1650,
      'areaId': 1207,
      'areaName': '万人大区',
      'serverId': 22311,
      'serverName': '紫气东来',
      'jobsName': '逍遥',
      'roleSexName': '男',
      'roleLevel': 109,
      'mainattributeattackName': '主火攻',
      'mattributeLevel': 4582,
      'subattributeItn': 1900,
      'viewNum': 343,
      'zhanghaoName': '畅游账号登录',
      'acSourceName': '神仙购买',
      'userName': '有话躺下说',
      'createTime': '2026-11-03T11:26:34+08:00',
      'lastTime': '2026-11-03T12:17:16+08:00',
      'canBargainId': 29,
      'canBargainName': '是',
      'minBargainPrice': '1600',
      'addPrice': '0.00',
      'ensureOpen': 1,
      'goodsDecs': '红熊王（直播间价格为1297）。顶变双10秦小偶。',
      'goodsTags': '稀有红熊王,红仙侣',
      'thumbnail': thumbnail ?? 'img/110/nocs/2026/10/29/cover',
      'goodsImages':
          images ??
          [
            {'id': 1, 'url': 'img/110/nocs/2026/10/29/p1'},
            {'id': 2, 'url': 'img/110/nocs/2026/10/29/p2'},
            {'id': 3, 'url': 'https://cdn.example.com/p3.png'},
            {'id': 4, 'url': 'img/110/nocs/2026/10/29/p1'}, // 重复 → 去重
          ],
      ...extra,
    },
  });
}

void main() {
  group('fetchSxdsGoodsDetail', () {
    test('成功：解析完整字段 + 全部图片（转 OSS 绝对地址并去重）', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter([_detailOk()]);
      dio.httpClientAdapter = adapter;

      final d = await fetchSxdsGoodsDetail(dio: dio, sn: ' TH356361 ');

      final req = adapter.requests.single;
      expect(req.uri.path, '/api/goods/goodsInfo');
      expect(req.queryParameters['goodsSn'], 'TH356361');
      // 站点签名头随请求携带
      expect(req.headers['timestamp'], isNotNull);
      expect(req.headers['visitauth'], isNotNull);

      expect(d.sn, 'TH356361');
      expect(d.title, '工作调动没时间玩了');
      expect(d.price, 1650);
      expect(d.area, '万人大区');
      expect(d.server, '紫气东来');
      expect(d.job, '逍遥');
      expect(d.sex, '男');
      expect(d.level, 109);
      expect(d.mainAtk, '主火攻');
      expect(d.attr, 4582);
      expect(d.attr2, 1900);
      expect(d.views, 343);
      expect(d.accountType, '畅游账号登录');
      expect(d.sourceName, '神仙购买');
      expect(d.seller, '有话躺下说');
      expect(d.createdAt, isNotNull);
      expect(d.canBargain, isTrue);
      expect(d.minBargainPrice, 1600);
      expect(d.hasEnsure, isTrue);
      expect(d.description, startsWith('红熊王'));
      expect(d.tags, ['稀有红熊王', '红仙侣']);
      // 3 张（重复图去重，绝对地址原样保留）
      expect(d.images, [
        'https://oss.sxds.com/img/110/nocs/2026/10/29/p1',
        'https://oss.sxds.com/img/110/nocs/2026/10/29/p2',
        'https://cdn.example.com/p3.png',
      ]);
      expect(d.cover, d.images.first);
      dio.close();
    });

    test(
      '不可议价（canBargainId=30 / canBargainName=否）→ canBargain=false',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _RecordingAdapter([
          _detailOk(
            extra: const {
              'canBargainId': 30,
              'canBargainName': '否',
              'minBargainPrice': null,
            },
          ),
        ]);

        final d = await fetchSxdsGoodsDetail(dio: dio, sn: 'TH352836');

        expect(d.canBargain, isFalse);
        expect(d.minBargainPrice, isNull);
        dio.close();
      },
    );

    test('议价字段缺失 → canBargain 为 null（不臆断为不可议价）', () async {
      final dio = Dio();
      dio.httpClientAdapter = _RecordingAdapter([
        _detailOk(
          extra: const {
            'canBargainId': null,
            'canBargainName': null,
            'minBargainPrice': null,
          },
        ),
      ]);

      final d = await fetchSxdsGoodsDetail(dio: dio, sn: 'TH343654');

      expect(d.canBargain, isNull);
      expect(d.minBargainPrice, isNull);
      dio.close();
    });

    test('无 goodsImages 时退回 thumbnail 作为唯一图片', () async {
      final dio = Dio();
      dio.httpClientAdapter = _RecordingAdapter([_detailOk(images: const [])]);

      final d = await fetchSxdsGoodsDetail(dio: dio, sn: 'TH356361');

      expect(d.images, ['https://oss.sxds.com/img/110/nocs/2026/10/29/cover']);
      dio.close();
    });

    test('code!=0 → 抛含 msg 的异常', () async {
      final dio = Dio();
      dio.httpClientAdapter = _RecordingAdapter([
        jsonEncode({'code': 1, 'data': {}, 'msg': 'goodsSn缺失'}),
      ]);

      await expectLater(
        fetchSxdsGoodsDetail(dio: dio, sn: 'X'),
        throwsA(
          isA<SxdsGoodsDetailException>().having(
            (e) => e.message,
            'message',
            contains('goodsSn缺失'),
          ),
        ),
      );
      dio.close();
    });

    test('data 为空 → 抛「未获取到商品详情」', () async {
      final dio = Dio();
      dio.httpClientAdapter = _RecordingAdapter([
        jsonEncode({'code': 0, 'data': <String, dynamic>{}}),
      ]);

      await expectLater(
        fetchSxdsGoodsDetail(dio: dio, sn: 'X'),
        throwsA(
          isA<SxdsGoodsDetailException>().having(
            (e) => e.message,
            'message',
            contains('未获取到商品详情'),
          ),
        ),
      );
      dio.close();
    });

    test('商品编号为空 → 直接抛异常且不发请求', () async {
      final dio = Dio();
      final adapter = _RecordingAdapter([_detailOk()]);
      dio.httpClientAdapter = adapter;

      await expectLater(
        fetchSxdsGoodsDetail(dio: dio, sn: '  '),
        throwsA(isA<SxdsGoodsDetailException>()),
      );
      expect(adapter.requests, isEmpty);
      dio.close();
    });
  });
}

/// 记录请求的适配器（按序返回给定响应体）。
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
