/// 神仙代售（sxds.com）站点接口的公共部分：签名头与图片地址规整。
///
/// 站点 JS 请求拦截器给每个接口请求注入两个 header（逆向自站方 bundle）：
/// - `timestamp`：秒级时间戳；
/// - `visitauth`：`SHA-256("$timestamp" + 固定密钥)` 的 Base64。
/// 不带签名会返回 `{"code":1,"msg":"访问权限失败"}`。
///
/// 账号行情 / 珍兽行情 / 商品详情三处抓取共用本文件，避免密钥与图片前缀
/// 在多份实现里各写一遍、改一处漏一处。
library;

import 'dart:convert' as conv;

import 'package:crypto/crypto.dart' as crypto;

/// 站点请求签名密钥（逆向自站方 JS）。
const String kSxdsSignSecret = 'lzadIuYtSA6CpdE0llu8';

/// 商品图 OSS 域名（接口返回的 `img/...` 相对路径需加此前缀）。
const String kSxdsImgOrigin = 'https://oss.sxds.com/';

/// 计算站点签名 header（`timestamp` + `visitauth`）。
Map<String, String> sxdsSignHeaders() {
  final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final digest = crypto.sha256
      .convert(conv.utf8.encode('$ts$kSxdsSignSecret'))
      .bytes;
  return {
    'timestamp': ts,
    'visitauth': conv.base64Encode(digest),
    'pragma': 'no-cache',
  };
}

/// 把平台图片路径规整为可加载的完整 URL。
///
/// - 已是 `http(s)://` → 原样返回；
/// - `img/...` 相对路径 → 加 [kSxdsImgOrigin] 前缀；
/// - 空/无效 → null。
String? sxdsResolveImg(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('/')) return '$kSxdsImgOrigin${t.substring(1)}';
  return '$kSxdsImgOrigin$t';
}
