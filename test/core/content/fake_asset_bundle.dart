import 'dart:convert';

import 'package:flutter/services.dart';

/// 用 Map 充当 assets：键是 `assets/catalog/...`，值是文件内容。
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final data = assets[key];
    if (data == null) throw StateError('Unable to load asset: $key');
    return ByteData.view(Uint8List.fromList(utf8.encode(data)).buffer);
  }
}
