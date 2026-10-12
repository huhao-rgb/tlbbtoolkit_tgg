import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';

void main() {
  test('generate：syncId 128 位 · masterKey 256 位，每次不同', () {
    final a = RegPairing.generate();
    final b = RegPairing.generate();

    expect(a.syncId, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(a.masterKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(a.syncIdRaw, hasLength(RegPairing.syncIdBytes));
    expect(a.masterKeyRaw, hasLength(RegPairing.masterKeyBytes));
    expect(a, isNot(b));
    expect(a.syncId, isNot(b.syncId));
    expect(a.masterKey, isNot(b.masterKey));
  });

  test('encode/decode：往返一致，配对码足够短（可手抄）', () {
    final p = RegPairing.generate();
    final code = p.encode();

    expect(code.startsWith(RegPairing.codePrefix), isTrue);
    // 48 字节 → 64 个 Base64Url 字符（无 padding）+ 5 字符前缀
    expect(code, hasLength(RegPairing.codePrefix.length + 64));

    final back = RegPairing.decode(code);
    expect(back.syncId, p.syncId);
    expect(back.masterKey, p.masterKey);
    expect(back, p);
  });

  test('decode：容忍折行 / 缺前缀（手抄与聊天窗口粘贴都能还原）', () {
    final p = RegPairing.generate();
    final code = p.encode();

    final wrapped = code.replaceAllMapped(RegExp('.{16}'), (m) => '${m[0]}\n');
    expect(RegPairing.decode(wrapped).masterKey, p.masterKey);
    expect(
      RegPairing.decode(code.substring(RegPairing.codePrefix.length)).syncId,
      p.syncId,
    );
    expect(RegPairing.decode('  $code  ').syncId, p.syncId);
  });

  test('decode：非法输入抛 FormatException', () {
    final p = RegPairing.generate();
    expect(() => RegPairing.decode(''), throwsFormatException);
    expect(() => RegPairing.decode('    '), throwsFormatException);
    // 误把一次性同步码（TGG1）贴进配对框
    expect(() => RegPairing.decode('TGG1:AAAA'), throwsFormatException);
    expect(() => RegPairing.decode('not base64 !!'), throwsFormatException);
    // 长度不符（10 字节 ≠ 48 字节）
    expect(
      () => RegPairing.decode(base64UrlEncode(List<int>.filled(10, 0))),
      throwsFormatException,
    );
    // 只有 syncId 长度的一半
    expect(() => RegPairing.decode(p.syncId), throwsFormatException);
  });

  test('构造期即校验格式；toString 不泄漏 masterKey', () {
    expect(
      () => RegPairing(syncId: 'zz', masterKey: 'a' * 64),
      throwsFormatException,
    );
    expect(
      () => RegPairing(syncId: 'a' * 32, masterKey: 'b' * 10),
      throwsFormatException,
    );

    final p = RegPairing.generate();
    expect(p.toString(), contains(p.syncId));
    expect(p.toString(), isNot(contains(p.masterKey)));
    expect(p.hashCode, p.syncId.hashCode);
  });
}
