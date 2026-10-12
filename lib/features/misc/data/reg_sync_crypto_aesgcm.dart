import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_crypto.dart';

/// [RegSyncCrypto] 的 AES-256-GCM 实现（纯 Dart，Web / 桌面 / 移动通用）。
///
/// 密钥派生：`HKDF-SHA256(ikm = masterKey, salt = syncId, info = 'tgg-reg-sync-v2')`
/// → 32 字节密钥。把 `syncId` 作为 salt 可以把密钥「绑」到这条云端记录上，
/// 避免同一个 masterKey 在两条记录间被复用。
///
/// 密文格式：`Base64Url(nonce ‖ cipherText ‖ tag)`，nonce 每次随机 12 字节
/// （GCM 下 nonce 重复是致命的，所以绝不能写死或用计数器）。
class RegSyncCryptoAesGcm implements RegSyncCrypto {
  const RegSyncCryptoAesGcm();

  /// GCM 标准 nonce 长度。
  static const int nonceLength = 12;

  /// GCM 认证标签长度。
  static const int macLength = 16;

  static final List<int> _hkdfInfo = utf8.encode('tgg-reg-sync-v2');
  static final RegExp _whitespace = RegExp(r'\s+');

  @override
  Future<String> seal({
    required RegPairing pairing,
    required String plaintext,
  }) async {
    final algorithm = AesGcm.with256bits();
    final box = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: await _deriveKey(pairing),
    );
    return base64UrlEncode(box.concatenation());
  }

  @override
  Future<String> open({
    required RegPairing pairing,
    required String blob,
  }) async {
    final compact = blob.replaceAll(_whitespace, '');
    final List<int> raw;
    try {
      raw = base64Url.decode(base64.normalize(compact));
    } on FormatException catch (e) {
      throw RegSyncCryptoException('密文不是合法的 Base64Url：${e.message}');
    }

    final SecretBox box;
    try {
      box = SecretBox.fromConcatenation(
        raw,
        nonceLength: nonceLength,
        macLength: macLength,
      );
    } on ArgumentError catch (e) {
      throw RegSyncCryptoException('密文长度不足：${e.message}');
    }

    final List<int> clear;
    try {
      clear = await AesGcm.with256bits().decrypt(
        box,
        secretKey: await _deriveKey(pairing),
      );
    } on SecretBoxAuthenticationError {
      // 密钥不符或密文被篡改 —— 两种情况都不该让调用方继续写云端。
      throw const RegSyncCryptoException('配对码与本机不一致，或云端数据已损坏');
    }
    try {
      return utf8.decode(clear);
    } on FormatException {
      throw const RegSyncCryptoException('解密结果不是合法的 UTF-8 文本');
    }
  }

  Future<SecretKey> _deriveKey(RegPairing pairing) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: RegPairing.masterKeyBytes,
    );
    return hkdf.deriveKey(
      secretKey: SecretKey(pairing.masterKeyRaw),
      nonce: pairing.syncIdRaw,
      info: _hkdfInfo,
    );
  }
}
