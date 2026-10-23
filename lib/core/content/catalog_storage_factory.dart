/// 打开数据目录缓存的具体存储实现。
///
/// 原生走文件、Web 走 SharedPreferences（条件导入避免把 `dart:io` 带进 Web 构建）。
library;

export 'catalog_storage_factory_stub.dart'
    if (dart.library.io) 'catalog_storage_factory_io.dart';
