/// 卡回归 —— 云端配对凭证（阶段 2「全自动同步」的身份基础）。
///
/// 设计要点：**把「找数据的 id」与「解密的密钥」拆开**。
/// - [syncId]：公开标识，客户端拿它去云端定位记录；即使泄漏也只暴露「有这条记录」；
/// - [masterKey]：只存在于本机，**永不上传**，服务端只见密文。
///
/// 配对码文本形如 `TGG2:<base64url>`（48 字节 → 64 字符，共 69 字符），
/// 比一次性传递用的同步码（`TGG1:`，250+ 字符）短得多，粘贴/手抄都轻松；
/// 两台设备各输入一次即可全自动同步。
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// 云端配对凭证。
@immutable
class RegPairing {
  /// 构造并校验格式（`syncId` 32 位十六进制、`masterKey` 64 位十六进制）。
  ///
  /// 构造期就校验：密钥格式错了应当立刻暴露，而不是等第一次解密失败才报错。
  RegPairing({required this.syncId, required this.masterKey}) {
    if (!_hexSyncId.hasMatch(syncId)) {
      throw FormatException('syncId 必须是 $syncIdHexLength 位十六进制', syncId);
    }
    if (!_hexMasterKey.hasMatch(masterKey)) {
      throw FormatException(
        'masterKey 必须是 $masterKeyHexLength 位十六进制',
        masterKey,
      );
    }
  }

  /// 配对码文本前缀（与一次性同步码 `TGG1:` 区分）。
  static const String codePrefix = 'TGG2:';

  /// [syncId] 的字节数 / 十六进制长度。
  static const int syncIdBytes = 16;
  static const int syncIdHexLength = syncIdBytes * 2;

  /// [masterKey] 的字节数 / 十六进制长度（AES-256）。
  static const int masterKeyBytes = 32;
  static const int masterKeyHexLength = masterKeyBytes * 2;

  static final RegExp _hexSyncId = RegExp('^[0-9a-f]{$syncIdHexLength}\$');
  static final RegExp _hexMasterKey = RegExp(
    '^[0-9a-f]{$masterKeyHexLength}\$',
  );
  static final RegExp _whitespace = RegExp(r'\s+');

  /// 公开标识（云端记录的 key）。
  final String syncId;

  /// 本机私钥（hex）；不要写进日志、不要上传。
  final String masterKey;

  /// 云端记录 key 的字节形式。
  Uint8List get syncIdRaw => _fromHex(syncId);

  /// 派生加密密钥的原始密钥material。
  Uint8List get masterKeyRaw => _fromHex(masterKey);

  /// 随机生成一份新配对（128 位 syncId + 256 位 masterKey）。
  factory RegPairing.generate() {
    final rnd = Random.secure();
    return RegPairing(
      syncId: _toHex([for (var i = 0; i < syncIdBytes; i++) rnd.nextInt(256)]),
      masterKey: _toHex([
        for (var i = 0; i < masterKeyBytes; i++) rnd.nextInt(256),
      ]),
    );
  }

  /// 编码为配对码文本（`TGG2:` + Base64Url(syncId ‖ masterKey)）。
  String encode() =>
      '$codePrefix${base64UrlEncode([...syncIdRaw, ...masterKeyRaw])}';

  /// 解析配对码文本。
  ///
  /// 宽容处理：忽略空白与换行、前缀可缺失（手抄或聊天窗口折行都能还原）；
  /// 长度/前缀不符则抛 [FormatException]（例如误把 `TGG1:` 同步码贴进来）。
  factory RegPairing.decode(String source) {
    final compact = source.replaceAll(_whitespace, '');
    if (compact.isEmpty) throw const FormatException('配对码为空');
    if (compact.startsWith('TGG1:')) {
      throw const FormatException('这是同步码（TGG1），不是配对码（TGG2）');
    }
    final body = compact.startsWith(codePrefix)
        ? compact.substring(codePrefix.length)
        : compact;

    final Uint8List raw;
    try {
      raw = Uint8List.fromList(base64Url.decode(base64.normalize(body)));
    } on FormatException catch (e) {
      throw FormatException('配对码不是合法的 Base64Url：${e.message}');
    }
    if (raw.length != syncIdBytes + masterKeyBytes) {
      throw FormatException(
        '配对码长度不正确（应为 ${syncIdBytes + masterKeyBytes} 字节，'
        '实际 ${raw.length} 字节）',
      );
    }
    return RegPairing(
      syncId: _toHex(raw.sublist(0, syncIdBytes)),
      masterKey: _toHex(raw.sublist(syncIdBytes)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RegPairing &&
      other.syncId == syncId &&
      other.masterKey == masterKey;

  /// 哈希只基于 [syncId]，避免把密钥material混进诊断输出。
  @override
  int get hashCode => syncId.hashCode;

  /// 只输出 [syncId]，**绝不**输出 [masterKey]。
  @override
  String toString() => 'RegPairing($syncId)';
}

String _toHex(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

Uint8List _fromHex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);
