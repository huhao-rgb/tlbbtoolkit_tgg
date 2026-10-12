import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_crypto.dart';

void main() {
  const crypto = RegSyncCryptoAesGcm();
  final pairing = RegPairing.generate();

  test('seal/open：往返一致（含中文与 JSON）', () async {
    const plain = '{"v":2,"accts":[{"name":"逍遥生","lv":89}]}';
    final blob = await crypto.seal(pairing: pairing, plaintext: plain);
    expect(await crypto.open(pairing: pairing, blob: blob), plain);
  });

  test('同一明文两次加密结果不同（nonce 每次随机）', () async {
    final a = await crypto.seal(pairing: pairing, plaintext: 'same');
    final b = await crypto.seal(pairing: pairing, plaintext: 'same');
    expect(a, isNot(b));
    expect(await crypto.open(pairing: pairing, blob: a), 'same');
    expect(await crypto.open(pairing: pairing, blob: b), 'same');
  });

  test('密文里搜不到明文（确认真的加密了，而不是编码）', () async {
    const secret = '逍遥生';
    final blob = await crypto.seal(pairing: pairing, plaintext: secret);
    final raw = base64Url.decode(base64.normalize(blob));
    // 原始字节与「按 UTF-8 解读成字符串」两种方式都找不到明文
    expect(String.fromCharCodes(raw), isNot(contains(secret)));
    expect(utf8.decode(raw, allowMalformed: true), isNot(contains(secret)));
  });

  test('masterKey 不符：解不开（同一个 syncId）', () async {
    final wrong = RegPairing(
      syncId: pairing.syncId,
      masterKey: RegPairing.generate().masterKey,
    );
    final blob = await crypto.seal(pairing: pairing, plaintext: 'x');
    expect(
      () => crypto.open(pairing: wrong, blob: blob),
      throwsA(isA<RegSyncCryptoException>()),
    );
  });

  test('syncId 不符：解不开（密钥与云端记录绑定）', () async {
    final wrong = RegPairing(
      syncId: RegPairing.generate().syncId,
      masterKey: pairing.masterKey,
    );
    final blob = await crypto.seal(pairing: pairing, plaintext: 'x');
    expect(
      () => crypto.open(pairing: wrong, blob: blob),
      throwsA(isA<RegSyncCryptoException>()),
    );
  });

  test('密文被篡改（翻转 tag 末位）→ 认证失败', () async {
    final blob = await crypto.seal(pairing: pairing, plaintext: 'x');
    final raw = base64Url.decode(base64.normalize(blob));
    raw[raw.length - 1] = raw[raw.length - 1] ^ 0x01;
    expect(
      () => crypto.open(pairing: pairing, blob: base64UrlEncode(raw)),
      throwsA(isA<RegSyncCryptoException>()),
    );
  });

  test('密文被截断 → 认证失败（不会静默返回残缺明文）', () async {
    final blob = await crypto.seal(pairing: pairing, plaintext: 'x' * 100);
    final raw = base64Url.decode(base64.normalize(blob));
    expect(
      () => crypto.open(
        pairing: pairing,
        blob: base64UrlEncode(raw.sublist(0, raw.length - 4)),
      ),
      throwsA(isA<RegSyncCryptoException>()),
    );
  });

  test('非法密文 → RegSyncCryptoException（不抛裸 FormatException）', () async {
    for (final bad in [
      '',
      '!!!',
      'AAAA',
      base64UrlEncode([1, 2, 3]),
    ]) {
      expect(
        () => crypto.open(pairing: pairing, blob: bad),
        throwsA(isA<RegSyncCryptoException>()),
        reason: '输入：$bad',
      );
    }
  });

  test('空白/折行的密文仍可解（聊天窗口折行不影响）', () async {
    final blob = await crypto.seal(pairing: pairing, plaintext: '折行');
    final wrapped = blob.replaceAllMapped(RegExp('.{16}'), (m) => '${m[0]}\n');
    expect(await crypto.open(pairing: pairing, blob: wrapped), '折行');
  });
}
