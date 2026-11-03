/// 神仙代售商品详情抓取（`GET /api/goods/goodsInfo`）。
///
/// 账号（`goodsTypeId=1`）与珍兽（`goodsTypeId=25`）共用同一个详情接口：
/// 传入列表里的 `goodsSn` 即可拿到该商品的完整字段与**全部商品图**
/// （列表接口只给一张封面缩略图）。
///
/// 请求同样需要站点签名头（见 `sxds_api.dart`）；Web 端被 CORS 拦截时
/// 抛 [SxdsGoodsDetailException.isWebBlocked]。
library;

import 'dart:convert' as conv;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tlbbtoolkit/features/misc/data/sxds_api.dart';
import 'package:tlbbtoolkit/features/misc/domain/sxds_goods_detail.dart';

/// 详情接口地址。
const String _kDetailApi = 'https://www.sxds.com/api/goods/goodsInfo';

/// 详情抓取异常。
class SxdsGoodsDetailException implements Exception {
  const SxdsGoodsDetailException(this.message, {required this.isWebBlocked});

  final String message;

  /// Web 端跨域（CORS）被浏览器拦截。
  final bool isWebBlocked;

  @override
  String toString() => message;
}

/// 抓取单个商品（账号 / 珍兽）的完整详情，含全部商品图。
///
/// [sn] 为列表接口返回的 `goodsSn`（如 `TH356361` / `BB260928111045097974`）。
Future<SxdsGoodsDetail> fetchSxdsGoodsDetail({
  Dio? dio,
  required String sn,
}) async {
  final id = sn.trim();
  if (id.isEmpty) {
    throw const SxdsGoodsDetailException('商品编号缺失', isWebBlocked: false);
  }
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
    final resp = await client.get<String>(
      _kDetailApi,
      queryParameters: {'goodsSn': id},
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          ...sxdsSignHeaders(),
          'Referer': 'https://www.sxds.com/detail/$id',
        },
      ),
    );
    return mapSxdsGoodsDetail(_parseBody(resp.data ?? ''));
  } on DioException catch (e) {
    final blocked = kIsWeb;
    throw SxdsGoodsDetailException(
      blocked ? '浏览器跨域拦截（CORS）' : '网络请求失败：${e.message ?? e.type}',
      isWebBlocked: blocked,
    );
  } on SxdsGoodsDetailException {
    rethrow;
  } catch (e) {
    throw SxdsGoodsDetailException('网络请求失败：$e', isWebBlocked: false);
  } finally {
    if (dio == null) client.close();
  }
}

/// 解析详情响应：期望 `{"code":0,"data":{...}}`（`data` 是单个对象）。
Map _parseBody(String body) {
  if (body.trimLeft().isEmpty) {
    throw const SxdsGoodsDetailException('接口返回为空', isWebBlocked: false);
  }
  dynamic json;
  try {
    json = conv.jsonDecode(body);
  } catch (_) {
    if (body.contains('<html') || body.contains('<!DOCTYPE')) {
      throw const SxdsGoodsDetailException(
        '接口返回非 JSON（可能被风控/验证页拦截）',
        isWebBlocked: false,
      );
    }
    throw const SxdsGoodsDetailException('接口返回格式异常', isWebBlocked: false);
  }
  if (json is! Map) {
    throw const SxdsGoodsDetailException('接口返回格式异常', isWebBlocked: false);
  }
  if (json['code'] != 0) {
    throw SxdsGoodsDetailException(
      '接口返回错误：${json['msg'] ?? '未知错误'}',
      isWebBlocked: false,
    );
  }
  final data = json['data'];
  if (data is! Map || data.isEmpty) {
    throw const SxdsGoodsDetailException('未获取到商品详情', isWebBlocked: false);
  }
  return data;
}

/// 把详情 `data` 映射为 [SxdsGoodsDetail]（账号 / 珍兽字段各自取名，缺省留空）。
SxdsGoodsDetail mapSxdsGoodsDetail(Map data) {
  final images = <String>[];
  final rawImages = data['goodsImages'];
  if (rawImages is List) {
    for (final g in rawImages) {
      final raw = g is Map ? (g['url'] ?? g['img'] ?? g['thumbnail']) : g;
      final url = raw is String ? sxdsResolveImg(raw) : null;
      if (url != null && !images.contains(url)) images.add(url);
    }
  }
  final thumb = data['thumbnail'];
  final cover = thumb is String ? sxdsResolveImg(thumb) : null;
  if (images.isEmpty && cover != null) images.add(cover);

  return SxdsGoodsDetail(
    sn: _str(data, ['goodsSn', 'sn']),
    title: _str(data, ['bigTitle', 'smallTitle', 'title', 'goodsName']).trim(),
    price: (_num(data, ['price']) ?? 0).round(),
    goodsTypeId: _num(data, ['goodsTypeId'])?.round(),
    goodsTypeName: _str(data, ['goodsTypeName']),
    area: _str(data, ['areaName']),
    server: _str(data, ['serverName']),
    areaId: _num(data, ['areaId'])?.round(),
    serverId: _num(data, ['serverId'])?.round(),
    job: _str(data, ['jobsName']),
    sex: _str(data, ['roleSexName']),
    level: (_num(data, ['roleLevel']) ?? 0).round(),
    mainAtk: _str(data, ['mainattributeattackName']),
    attr: (_num(data, ['mattributeLevel']) ?? 0).round(),
    attr2: (_num(data, ['subattributeItn']) ?? 0).round(),
    petLevel: _str(data, ['baobaoLevel']),
    carryText: _str(data, ['packName']),
    ling: _str(data, ['lingxingName']),
    wu: _str(data, ['wuxingName']),
    locked: _parseLock(data['lockName']),
    views: (_num(data, ['viewNum']) ?? 0).round(),
    accountType: _str(data, ['zhanghaoName']),
    sourceName: _str(data, ['acSourceName']),
    seller: _str(data, ['userName']),
    createdAt: _parseTime(data['createTime']),
    updatedAt: _parseTime(data['lastTime']),
    canBargain: _parseBargain(data),
    minBargainPrice: _num(data, ['minBargainPrice'])?.round(),
    addPrice: (_num(data, ['addPrice']) ?? 0).round(),
    hasEnsure: (_num(data, ['ensureOpen']) ?? 0) > 0,
    description: _str(data, ['goodsDecs', 'description']).trim(),
    tags: _parseTags(data['goodsTags']),
    images: images,
  );
}

String _str(Map data, List<String> keys) {
  for (final k in keys) {
    final v = data[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return '';
}

num? _num(Map data, List<String> keys) {
  for (final k in keys) {
    final v = data[k];
    if (v is num) return v;
    if (v is String && double.tryParse(v) != null) return double.parse(v);
  }
  return null;
}

/// 是否可议价：平台 `canBargainName` 为「是/否」；缺省时退回枚举 id
/// （29=是 / 30=否）。两者都没有 → null（平台未标注，不要臆断成「不议价」）。
bool? _parseBargain(Map data) {
  final name = _str(data, ['canBargainName']);
  if (name == '是') return true;
  if (name == '否') return false;
  return switch (_num(data, ['canBargainId'])?.round()) {
    29 => true,
    30 => false,
    _ => null,
  };
}

/// 珍兽是否上锁（平台 `lockName` = 是/否）；未标注 → null。
bool? _parseLock(dynamic v) {
  if (v is! String) return null;
  if (v == '是') return true;
  if (v == '否') return false;
  return null;
}

/// 平台时间字符串（ISO8601，带时区）→ [DateTime]；无法解析返回 null。
DateTime? _parseTime(dynamic v) {
  if (v is! String || v.trim().isEmpty) return null;
  return DateTime.tryParse(v.trim());
}

/// 商品亮点：平台用逗号 / 顿号 / 空格分隔的短标签串。
List<String> _parseTags(dynamic v) {
  if (v is! String) return const [];
  return v
      .split(RegExp(r'[,，、\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}
