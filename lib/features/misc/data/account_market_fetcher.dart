/// 账号行情 —— 神仙代售平台真实数据抓取（对应原型 `amFetch` / `amRequestReal`）。
///
/// 真实接口（经逆向页面 JS 确认）：
/// `GET https://www.sxds.com/api/goods/getGoodsList`，必填
/// `gameId=74&goodsTypeId=1&pages=N&pageSize=M`（goodsTypeId=1 为「游戏账号」类目），
/// 可选筛选参数 `areaId / serverId / roleLevelLimit`（等级段 `min-max`，如 '60-70'）。
///
/// 鉴权与「珍兽行情」相同：站点 JS 请求拦截器注入 `timestamp` + `visitauth`
/// （SHA-256 签名 Base64），不带签名返回 `{"code":1,"msg":"访问权限失败"}`。
///
/// Web 端被浏览器 CORS 拦截时会抛 [AccountMarketFetchException.isWebBlocked]；
/// 桌面/移动端可直连（接口不要求登录态）。
library;

import 'dart:convert' as conv;

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/account_market.dart';

/// 站点请求签名密钥（逆向自站方 JS，与珍兽行情共用）。
const String _kSignSecret = 'lzadIuYtSA6CpdE0llu8';

/// 真实接口地址（gameId=74 天龙怀旧服；goodsTypeId=1 账号类目）。
const String _kApiBase = 'https://www.sxds.com/api/goods/getGoodsList';

/// 商品图 OSS 域名（thumbnail 为相对路径，需加此前缀）。
const String _kImgOrigin = 'https://oss.sxds.com/';

/// 把平台缩略图路径规整为可加载的完整 URL。
///
/// - 已是 `http(s)://` → 原样返回；
/// - `img/...` 相对路径 → 加 `https://oss.sxds.com/` 前缀；
/// - 空/无效 → null。
String? _resolveImg(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('/')) return '$_kImgOrigin${t.substring(1)}';
  return '$_kImgOrigin$t';
}

/// 从商品原始记录解析主图 URL（thumbnail / goodsImages 主图均可）。
String? _pickImg(dynamic item) {
  if (item is! Map) return null;
  final thumb = item['thumbnail'];
  if (thumb is String) {
    final u = _resolveImg(thumb);
    if (u != null) return u;
  }
  final gi = item['goodsImages'];
  if (gi is List && gi.isNotEmpty) {
    for (final g in gi) {
      if (g is String) {
        final u = _resolveImg(g);
        if (u != null) return u;
      } else if (g is Map) {
        final raw = g['url'] ?? g['img'] ?? g['thumbnail'];
        if (raw is String) {
          final u = _resolveImg(raw);
          if (u != null) return u;
        }
      }
    }
  } else if (gi is Map) {
    final raw = gi['url'] ?? gi['img'] ?? gi['thumbnail'];
    if (raw is String) {
      final u = _resolveImg(raw);
      if (u != null) return u;
    }
  }
  return null;
}

/// 抓取异常。
class AccountMarketFetchException implements Exception {
  const AccountMarketFetchException(this.message, {required this.isWebBlocked});

  final String message;

  /// Web 端跨域（CORS）被浏览器拦截。
  final bool isWebBlocked;

  @override
  String toString() => message;
}

/// 抓取结果。
class AccountMarketFetchResult {
  const AccountMarketFetchResult({required this.raw, required this.parsed});

  /// 原始商品记录条数（来自 goodsList）。
  final int raw;

  /// 能映射成账号的条目（可刷新统计）。
  final List<AccountListing> parsed;
}

/// 计算站点签名 header（timestamp + visitauth）。
Map<String, String> _signHeaders() {
  final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final digest = crypto.sha256
      .convert(conv.utf8.encode('$ts$_kSignSecret'))
      .bytes;
  return {
    'timestamp': ts,
    'visitauth': conv.base64Encode(digest),
    'pragma': 'no-cache',
  };
}

/// 解析单页响应：期望 `{"code":0,"data":{"goodsList":[...]}}`。
///
/// 返回 `(goodsList, total)`；任何异常都抛 [AccountMarketFetchException]。
(List<dynamic>, int) _parseBody(String body) {
  if (body.trimLeft().isEmpty) {
    throw const AccountMarketFetchException('接口返回为空', isWebBlocked: false);
  }
  dynamic json;
  try {
    json = conv.jsonDecode(body);
  } catch (_) {
    if (body.contains('<html') || body.contains('<!DOCTYPE')) {
      throw const AccountMarketFetchException(
        '接口返回非 JSON（可能被风控/验证页拦截）',
        isWebBlocked: false,
      );
    }
    throw const AccountMarketFetchException('接口返回格式异常', isWebBlocked: false);
  }
  if (json is! Map) {
    throw const AccountMarketFetchException('接口返回格式异常', isWebBlocked: false);
  }
  final code = json['code'];
  if (code != 0) {
    throw AccountMarketFetchException(
      '接口返回错误：${json['msg'] ?? '未知错误'}',
      isWebBlocked: false,
    );
  }
  final data = json['data'];
  final goodsList = data is Map ? data['goodsList'] : null;
  if (goodsList is! List) {
    throw const AccountMarketFetchException('接口返回格式异常（无商品列表）', isWebBlocked: false);
  }
  final total = data is Map ? (data['total'] as num?)?.toInt() ?? 0 : 0;
  return (goodsList, total);
}

/// 候选键读取（真实平台字段名与快照不同，做宽容兼容）。
String _pickStr(dynamic item, List<String> keys, [String fallback = '']) {
  if (item is! Map) return fallback;
  for (final k in keys) {
    final v = item[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return fallback;
}

num? _pickNum(dynamic item, List<String> keys) {
  if (item is! Map) return null;
  for (final k in keys) {
    final v = item[k];
    if (v is num) return v;
    if (v is String && double.tryParse(v) != null) return double.parse(v);
  }
  return null;
}

/// 把 goodsList 单条原始记录映射为 [AccountListing]。
///
/// 字段口径与 `ACC_DATA` 快照一致（n/t/p/v/a/s/job/sex/lv/atk/attr/attr2）。
/// 真实平台字段名不同时做候选兼容；映射不出标题/价格的记录直接跳过。
AccountListing? _mapGood(dynamic item) {
  if (item is! Map) return null;
  final title = _pickStr(item, [
    'bigTitle',
    't',
    'title',
    'name',
    'goodsName',
    'subTitle',
    '商品标题',
  ]).trim();
  final price = _pickNum(item, ['price', 'p', 'salePrice', 'unitPrice', '售价']);
  if (title.isEmpty || price == null) return null;
  return AccountListing(
    sn: _pickStr(item, ['goodsSn', 'sn', 'id', 'goodsId', 'productNo', '编号']),
    title: title,
    price: price.round(),
    views: (_pickNum(item, ['viewNum', 'v', 'views', '浏览量']) ?? 0).round(),
    area: _pickStr(item, ['areaName', 'a', 'area', 'serverArea', '大区']),
    server: _pickStr(item, [
      'serverName',
      's',
      'server',
      'serverZone',
      '服务器',
    ]),
    job: _pickStr(item, ['jobsName', 'job', 'jobName', '职业']),
    sex: _pickStr(item, ['roleSexName', 'sex', 'gender', '性别']),
    lv: (_pickNum(item, ['roleLevel', 'lv', 'level', '等级']) ?? 0).round(),
    atk: _pickStr(item, [
      'mainattributeattackName',
      'atk',
      'mainAtk',
      '主属性攻击',
    ]),
    attr: (_pickNum(item, ['mattributeLevel', 'attr', 'mainAttr', '主属性']) ?? 0)
        .round(),
    attr2: (_pickNum(item, ['subattributeItn', 'attr2', 'subAttr', '副属性']))
        ?.round(),
    areaId: (_pickNum(item, ['areaId', '大区id']))?.round(),
    serverId: (_pickNum(item, ['serverId', '服务器id']))?.round(),
    img: _pickImg(item),
  );
}

/// 抓取查询条件（对应页面顶部筛选 → 平台接口参数）。
///
/// 均为可选；为空表示「全部」。已选任一项时按该条件分页拉取到全部数据；
/// 全空（全部大区/全部服务器/全部等级）则只取前 [fetchSxdsAccountMarket] 的
/// [fetchSxdsAccountMarket.pages] 页（默认前 400 条）作为行情快照。
@immutable
class AccountMarketQuery {
  const AccountMarketQuery({this.areaId, this.serverId, this.levelLimit});

  /// 平台大区 id（如 320 = 怀旧一区）。
  final int? areaId;

  /// 平台服务器 id（可逗号分隔多值字符串传入）。
  final String? serverId;

  /// 平台等级段参数（`min-max`，如 '60-70'）；null=全部。
  final String? levelLimit;

  bool get isEmpty => areaId == null && serverId == null && levelLimit == null;
}

/// 分页抓取神仙代售账号类目在售列表。
///
/// 抓取策略与珍兽行情一致：
/// - [query] 为空（全部）→ 至多抓 [pages] 页（默认 2 × 200 = 前 400 条）；
/// - [query] 带筛选 → 从第 1 页起持续翻页，直到某页不足 [pageSize]。
///
/// 请求带站点签名头；返回去重后的 [AccountMarketFetchResult]。
Future<AccountMarketFetchResult> fetchSxdsAccountMarket({
  Dio? dio,
  int pages = 2,
  int pageSize = 200,
  AccountMarketQuery query = const AccountMarketQuery(),
}) async {
  if (pages < 1) pages = 1;
  if (pageSize < 1) pageSize = 12;
  final filtered = !query.isEmpty;
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
          headers: const {'Accept': 'application/json, text/plain, */*'},
        ),
      );
  try {
    var raw = 0;
    final seen = <String>{};
    final goods = <dynamic>[];
    for (var p = 1; p <= (filtered ? 1 << 30 : pages); p++) {
      final params = <String, dynamic>{
        'gameId': 74,
        'goodsTypeId': 1,
        'pages': p,
        'pageSize': pageSize,
      };
      if (query.areaId != null) params['areaId'] = query.areaId;
      if (query.serverId != null && query.serverId!.isNotEmpty) {
        params['serverId'] = query.serverId;
      }
      if (query.levelLimit != null && query.levelLimit!.isNotEmpty) {
        params['roleLevelLimit'] = query.levelLimit;
      }

      final resp = await client.get<String>(
        _kApiBase,
        queryParameters: params,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            ..._signHeaders(),
            'Referer': 'https://www.sxds.com/wares/',
          },
        ),
      );
      final (goodsList, _) = _parseBody(resp.data ?? '');
      for (final g in goodsList) {
        final key = g is Map ? '${g['id'] ?? g['goodsSn'] ?? g['sn']}' : '';
        if (key.isNotEmpty && !seen.add(key)) continue;
        goods.add(g);
      }
      raw += goodsList.length;
      // 已到底（不足一页）或已无更多 → 结束。
      if (goodsList.length < pageSize) break;
      // 安全兜底：防止异常情况下无限翻页。
      if (p >= 200) break;
    }
    if (goods.isEmpty) {
      throw const AccountMarketFetchException('未获取到商品数据', isWebBlocked: false);
    }
    final parsed = <AccountListing>[];
    for (final g in goods) {
      final m = _mapGood(g);
      if (m != null) parsed.add(m);
    }
    return AccountMarketFetchResult(raw: raw, parsed: parsed);
  } on DioException catch (e) {
    final blocked = kIsWeb;
    throw AccountMarketFetchException(
      blocked ? '浏览器跨域拦截（CORS）' : '网络请求失败：${e.message ?? e.type}',
      isWebBlocked: blocked,
    );
  } on AccountMarketFetchException {
    rethrow;
  } catch (e) {
    throw AccountMarketFetchException('网络请求失败：$e', isWebBlocked: false);
  } finally {
    if (dio == null) client.close();
  }
}
