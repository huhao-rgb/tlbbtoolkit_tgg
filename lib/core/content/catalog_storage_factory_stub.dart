import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/content/catalog_storage.dart';

/// Web：浏览器没有可写文件系统，落到 SharedPreferences（localStorage）。
///
/// 这不是降级 —— localStorage 有 5MB 配额，当前全量分片约 500KB，够用；
/// 缓存与「下次启动生效」的语义在 Web 上同样成立（刷新页面即重新读缓存）。
Future<CatalogStorage> openCatalogStorage({
  required SharedPreferences prefs,
}) async => PrefsCatalogStorage(prefs);
