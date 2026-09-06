/// 珍兽行情 —— 神仙代售平台真实数据抓取（对应原型 `pmFetchLatest`）。
///
/// 真实接口（经逆向页面 JS 确认）：
/// `GET https://www.sxds.com/api/goods/getGoodsList`，必填
/// `gameId=74&goodsTypeId=25&pages=N&pageSize=M`，可选筛选参数
/// `areaId / wuxingId / lingxingId / serverId / packId / keyWord`。
///
/// 鉴权：站点 JS 请求拦截器注入两个 header ——
/// - `timestamp`：当前秒级时间戳；
/// - `visitauth`：`SHA-256("$timestamp" + 固定密钥)` 的 Base64。
///   密钥硬编码在站方 bundle（`ggmm(timestamp,"lzadIuYtSA6CpdE0llu8")`）。
/// 不带签名会返回 `{"code":1,"msg":"访问权限失败"}`。
///
/// 原型抓的是 `wares/` HTML 里的 NUXT payload —— 但真实 NUXT 是 IIFE
/// （`window.__NUXT__=(function(a,b){...})(...)`）而非纯 JSON，jsonDecode
/// 必然失败，这就是旧实现抛「页面数据格式异常」的根因。本实现改为直连
/// 该接口（SSR 服务端同款数据源），字段与页面 `goodsList` 完全一致。
///
/// Web 端被浏览器 CORS 拦截时会抛 [PetMarketFetchException.isWebBlocked]；
/// 桌面/移动端可直连（接口不要求登录态）。
library;

import 'dart:convert' as conv;

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/pet_market.dart';

/// 站点请求签名密钥（逆向自站方 JS）。
const String _kSignSecret = 'lzadIuYtSA6CpdE0llu8';

/// 真实接口地址（gameId=74 天龙怀旧服；goodsTypeId=25 宝宝类目）。
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
  // thumbnail 字符串
  final thumb = item['thumbnail'];
  if (thumb is String) {
    final u = _resolveImg(thumb);
    if (u != null) return u;
  }
  // goodsImages 数组/含主图
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
class PetMarketFetchException implements Exception {
  const PetMarketFetchException(this.message, {required this.isWebBlocked});

  final String message;

  /// Web 端跨域（CORS）被浏览器拦截。
  final bool isWebBlocked;

  @override
  String toString() => message;
}

/// 抓取结果。
class PetMarketFetchResult {
  const PetMarketFetchResult({required this.raw, required this.parsed});

  /// 原始商品记录条数（来自 goodsList）。
  final int raw;

  /// 能按快照字段映射出来的商品（可刷新统计）。
  final List<PetListing> parsed;
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
/// 返回 `(goodsList, total)`；任何异常都抛 [PetMarketFetchException]。
(List<dynamic>, int) _parseBody(String body) {
  if (body.trimLeft().isEmpty) {
    throw const PetMarketFetchException('接口返回为空', isWebBlocked: false);
  }
  dynamic json;
  try {
    json = conv.jsonDecode(body);
  } catch (_) {
    if (body.contains('<html') || body.contains('<!DOCTYPE')) {
      throw const PetMarketFetchException(
        '接口返回非 JSON（可能被风控/验证页拦截）',
        isWebBlocked: false,
      );
    }
    throw const PetMarketFetchException('接口返回格式异常', isWebBlocked: false);
  }
  if (json is! Map) {
    throw const PetMarketFetchException('接口返回格式异常', isWebBlocked: false);
  }
  final code = json['code'];
  if (code != 0) {
    throw PetMarketFetchException(
      '接口返回错误：${json['msg'] ?? '未知错误'}',
      isWebBlocked: false,
    );
  }
  final data = json['data'];
  final goodsList = data is Map ? data['goodsList'] : null;
  if (goodsList is! List) {
    throw const PetMarketFetchException('接口返回格式异常（无商品列表）', isWebBlocked: false);
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

bool _pickBool(dynamic item, List<String> keys) {
  if (item is! Map) return false;
  for (final k in keys) {
    final v = item[k];
    if (v == true || v == 1) return true;
    if (v is String && (v == 'true' || v == '1')) return true;
  }
  return false;
}

/// 从标题/备注文本推断资质、性格、双十、顶变等标签。
///
/// 真实 API 不直接给出这些结构化字段（只有 bigTitle/goodsTags 文本），
/// 快照的 `apt/ch/ss/ding` 本就是从标题人工标注而来，这里做启发式还原：
/// - 资质：`数字资质` / `资质数字`（≥3 位）或标题内裸 4 位数字兜底；
/// - 双十/顶变/技能全：命中关键词；性格：命中常见性格词表。
void _inferTags(
  String text, {
  required void Function(int?) setApt,
  required void Function(bool) setSs,
  required void Function(bool) setDing,
  required void Function(int?) setSkill,
  required void Function(String?) setCh,
}) {
  final t = text.trim();
  if (t.isEmpty) return;
  int? apt;
  final m1 = RegExp(r'(\d{3,4})\s*\+?\s*资质').firstMatch(t);
  if (m1 != null) {
    apt = int.tryParse(m1.group(1)!);
  } else {
    final m2 = RegExp(r'资质\s*[:：]?\s*(\d{3,4})').firstMatch(t);
    if (m2 != null) apt = int.tryParse(m2.group(1)!);
  }
  if (apt == null) {
    final m3 = RegExp(r'(?<![\d.])(\d{4})(?![\d.])').firstMatch(t);
    if (m3 != null) apt = int.tryParse(m3.group(1)!);
  }
  setApt(apt);
  setSs(t.contains('双十'));
  setDing(t.contains('顶变'));
  final sk = RegExp(r'技能全\s*(\d+)').firstMatch(t);
  setSkill(sk == null ? null : int.tryParse(sk.group(1)!));

  const chWords = <String>[
    '谨慎',
    '胆小',
    '勇猛',
    '忠诚',
    '精明',
    '冷静',
    '狂野',
    '忠厚',
    '慎重',
  ];
  String? ch;
  for (final w in chWords) {
    if (t.contains(w)) {
      ch = w;
      break;
    }
  }
  setCh(ch);
}

/// 从可携带等级文本（如 `85级` / `85`）提取整数；无则 null。
int? _parseCarry(String? s) {
  if (s == null) return null;
  final m = RegExp(r'(\d{1,3})').firstMatch(s.trim());
  if (m == null) return null;
  final v = int.tryParse(m.group(1)!);
  return v != null && v > 0 ? v : null;
}

/// 把 goodsList 单条原始记录映射为 [PetListing]。
///
/// 字段口径与 `PET_DATA` 快照一致（t/p/a/s/lv/lx/wx/pet/ch/apt/ss/ding/
/// sk/cl/v/sn）。真实平台字段名不同时做候选兼容；映射不出标题/价格的
/// 记录直接跳过（不计入 [PetMarketFetchResult.parsed]）。
PetListing? _mapGood(dynamic item) {
  if (item is! Map) return null;

  // 标题：真实平台 bigTitle 常带尾部空格（如 "50灵 4500资质 "）。
  var title = _pickStr(item, [
    'bigTitle',
    't',
    'title',
    'name',
    'goodsName',
    'subTitle',
    '商品标题',
  ]).trim();
  if (title.isEmpty) {
    final tags = _pickStr(item, ['goodsTags', 'tags', '备注', '商品标签']).trim();
    if (tags.isNotEmpty) {
      title = tags.length > 20 ? tags.substring(0, 20) : tags;
    }
  }
  final price = _pickNum(item, ['price', 'p', 'salePrice', 'unitPrice', '售价']);
  if (title.isEmpty || price == null) return null;

  final sn = _pickStr(item, [
    'goodsSn',
    'sn',
    'id',
    'productNo',
    'goodsId',
    '编号',
  ]);
  final area = _pickStr(item, ['areaName', 'a', 'area', 'serverArea', '大区']);
  final server = _pickStr(item, [
    'serverName',
    's',
    'server',
    'serverZone',
    '服务器',
  ]);

  // 平台大区/服务器 id（用于按区服重新拉取）。
  final areaId = (_pickNum(item, ['areaId', '大区id']))?.round();
  final serverId = (_pickNum(item, ['serverId', '服务器id']))?.round();

  // 主图完整 URL（OSS）。
  final img = _pickImg(item);

  // 珍兽当前等级（真实 baobaoLevel 是字符串如 "89"）。
  // 珍兽当前等级（真实 baobaoLevel 是字符串如 "89"）。
  final lv =
      (_pickNum(item, ['baobaoLevel', 'lv', 'level', 'needLevel', '等级']) ?? 0)
          .round();

  // 平台可携带等级档位（权威）：packId 52-56 / packName "95级"…
  final packId = (_pickNum(item, ['packId', 'carryId', '携带等级档位']))?.round();
  final packName = _pickStr(item, ['packName', 'carryName', '可携带等级']).trim();

  // 数字兜底：packName 带数字（"85级"→85）时取之；"其他等级"无数值。
  final carry = packName.isNotEmpty
      ? _parseCarry(packName)
      : (_pickNum(item, ['cl', 'carry', 'carryLevel', '携带等级'])?.round());

  final views = (_pickNum(item, ['viewNum', 'v', 'views', '浏览量']) ?? 0).round();

  // 灵性/五行：真实返回文本（如 "10"），无则回退数字字段。
  final ling = _pickStr(item, ['lingxingName', 'lx', 'ling', '灵性'], '0');
  final wu = _pickStr(item, ['wuxingName', 'wx', 'wu', '悟性'], '0');

  // 结构化标签启发式还原（真接口只有文本）。
  int? apt;
  bool ss = false;
  bool ding = false;
  int? skill;
  String? ch;
  _inferTags(
    '$title ${_pickStr(item, ['goodsTags', 'smallTitle', 'tags', '备注'])}',
    setApt: (v) => apt = v,
    setSs: (v) => ss = v,
    setDing: (v) => ding = v,
    setSkill: (v) => skill = v,
    setCh: (v) => ch = v,
  );
  // 若真实 API 直接给出结构化字段则优先采用。
  final rawApt = _pickNum(item, ['apt', 'aptitude', '资质']);
  if (rawApt != null) apt = rawApt.round();
  if (_pickBool(item, ['isSs', 'ss', '双十'])) ss = true;
  if (_pickBool(item, ['isDing', 'ding', '顶变'])) ding = true;
  final rawSk = _pickNum(item, ['sk', 'skillFull', '技能全']);
  if (rawSk != null) skill = rawSk.round();
  final rawCh = _pickStr(item, ['ch', 'char', '性格']);
  if (rawCh.isNotEmpty) ch = rawCh;

  return PetListing(
    title: title,
    price: price.round(),
    area: area,
    server: server,
    lv: lv,
    ling: ling,
    wu: wu,
    pet: _pickStr(item, ['pet', 'petType', '品种'], '其他'),
    ch: ch,
    apt: apt,
    ss: ss,
    ding: ding,
    skill: skill,
    carry: carry,
    views: views,
    sn: sn.isEmpty ? 'S${DateTime.now().millisecondsSinceEpoch}' : sn,
    areaId: areaId,
    serverId: serverId,
    packId: packId,
    packName: packName.isEmpty ? null : packName,
    img: img,
  );
}

/// 抓取查询条件（对应页面顶部筛选 → 平台接口参数）。
///
/// 均为可选；为空表示「全部」。已选任一项时按该条件分页拉取到全部数据；
/// 全空（全部大区/全部服务器/全部携带等级）则只取前 [fetchSxdsMarket] 的
/// [fetchSxdsMarket.pages] 页（默认前 400 条）作为行情快照。
@immutable
class PetMarketQuery {
  const PetMarketQuery({this.areaId, this.serverId, this.packId});

  /// 平台大区 id（如 1207 = 万人大区）。
  final int? areaId;

  /// 平台服务器 id（如 22311 = 紫气东来；可逗号分隔多值字符串传入）。
  final String? serverId;

  /// 可携带等级档位（52=95级/53=85级/54=75级/55=65级/56=其他）。
  final int? packId;

  bool get isEmpty => areaId == null && serverId == null && packId == null;
}

/// 平台一个大区（来自 `gamefilter` 区服目录）。
@immutable
class SxdsRegion {
  const SxdsRegion({
    required this.areaId,
    required this.areaName,
    this.servers = const [],
  });

  final int areaId;
  final String areaName;
  final List<SxdsServer> servers;
}

/// 平台一个服务器。
@immutable
class SxdsServer {
  const SxdsServer({required this.serverId, required this.serverName});

  final int serverId;
  final String serverName;
}

/// 拉取平台区服目录（`/api/comm/gamefilter`）。
///
/// 返回该游戏下全部大区与服务器（用于顶部大区/服务器下拉的固定候选，
/// 不随当前聚焦数据缩水）。失败（Web CORS/网络）时抛 [PetMarketFetchException]。
Future<List<SxdsRegion>> fetchSxdsRegions({
  Dio? dio,
  String base = 'https://www.sxds.com/api/comm/gamefilter',
}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json, text/plain, */*'},
        ),
      );
  try {
    final resp = await client.get<String>(
      base,
      queryParameters: {'gameId': 74},
      options: Options(
        responseType: ResponseType.plain,
        headers: {..._signHeaders(), 'Referer': 'https://www.sxds.com/wares/'},
      ),
    );
    final body = resp.data ?? '';
    dynamic json;
    try {
      json = conv.jsonDecode(body);
    } catch (_) {
      throw const PetMarketFetchException('接口返回格式异常', isWebBlocked: false);
    }
    if (json is! Map || json['code'] != 0) {
      throw PetMarketFetchException(
        '接口返回错误：${json is Map ? json['msg'] : '未知'}',
        isWebBlocked: false,
      );
    }
    final data = json['data'];
    if (data is! Map) {
      throw const PetMarketFetchException('接口返回格式异常（无数据）', isWebBlocked: false);
    }
    // data 是 "1".."N" 的筛选项字典，取 fieldKey==areaId 那组。
    dynamic areaFilter;
    for (final v in data.values) {
      if (v is Map && v['fieldKey'] == 'areaId') {
        areaFilter = v;
        break;
      }
    }
    final options = areaFilter is Map ? areaFilter['options'] : null;
    if (options is! List) {
      return const [];
    }
    final regions = <SxdsRegion>[];
    for (final o in options) {
      if (o is! Map) continue;
      final aid = o['specialId'];
      final name = o['specialName'];
      if (aid is! num || name is! String || name.isEmpty) continue;
      final servers = <SxdsServer>[];
      final sec = o['secondOptions'];
      if (sec is List) {
        for (final s in sec) {
          if (s is! Map) continue;
          final sid = s['twoSpecialId'];
          final sname = s['twoSpecialName'];
          if (sid is num && sname is String && sname.isNotEmpty) {
            servers.add(SxdsServer(serverId: sid.round(), serverName: sname));
          }
        }
      }
      regions.add(
        SxdsRegion(
          areaId: aid.round(),
          areaName: name.trim(),
          servers: servers,
        ),
      );
    }
    return regions;
  } on DioException catch (e) {
    final blocked = kIsWeb;
    throw PetMarketFetchException(
      blocked ? '浏览器跨域拦截（CORS）' : '网络请求失败：${e.message ?? e.type}',
      isWebBlocked: blocked,
    );
  } on PetMarketFetchException {
    rethrow;
  } catch (e) {
    throw PetMarketFetchException('网络请求失败：$e', isWebBlocked: false);
  } finally {
    if (dio == null) client.close();
  }
}

/// 分页抓取神仙代售宝宝类目在售列表。
///
/// 抓取策略：
/// - [query] 为空（全部）→ 至多抓 [pages] 页（默认 2 × 200 = 前 400 条，
///   平台宝宝类目总量大，全部拉取不现实）；
/// - [query] 带筛选（选了大区/服务器/携带等级）→ 从第 1 页起持续翻页，
///   直到某页不足 [pageSize]（即该筛选下已取尽）。
///
/// 请求带站点签名头；返回去重后的 [PetMarketFetchResult]。
Future<PetMarketFetchResult> fetchSxdsMarket({
  Dio? dio,
  int pages = 2,
  int pageSize = 200,
  PetMarketQuery query = const PetMarketQuery(),
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
        'goodsTypeId': 25,
        'pages': p,
        'pageSize': pageSize,
      };
      if (query.areaId != null) params['areaId'] = query.areaId;
      if (query.serverId != null && query.serverId!.isNotEmpty) {
        params['serverId'] = query.serverId;
      }
      if (query.packId != null) params['packId'] = query.packId;

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
      throw const PetMarketFetchException('未获取到商品数据', isWebBlocked: false);
    }
    final parsed = <PetListing>[];
    for (final g in goods) {
      final m = _mapGood(g);
      if (m != null) parsed.add(m);
    }
    return PetMarketFetchResult(raw: raw, parsed: parsed);
  } on DioException catch (e) {
    final blocked = kIsWeb;
    throw PetMarketFetchException(
      blocked ? '浏览器跨域拦截（CORS）' : '网络请求失败：${e.message ?? e.type}',
      isWebBlocked: blocked,
    );
  } on PetMarketFetchException {
    rethrow;
  } catch (e) {
    throw PetMarketFetchException('网络请求失败：$e', isWebBlocked: false);
  } finally {
    if (dio == null) client.close();
  }
}
