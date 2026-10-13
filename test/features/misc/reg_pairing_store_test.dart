import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/core/storage/secure_kv_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';

/// 内存版安全存储，可模拟后端故障。
class _MemorySecureStore implements SecureKvStore {
  final Map<String, String> data = {};

  /// 读接口抛错（模拟 Android 换机后 Keystore 密钥丢失）。
  bool failReads = false;

  /// 写/删接口抛错（模拟 Linux 缺 libsecret、Web 非 HTTPS）。
  bool failWrites = false;

  int deleteCount = 0;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('secure backend down');
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('secure backend down');
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failWrites) throw StateError('secure backend down');
    deleteCount++;
    data.remove(key);
  }
}

void main() {
  late _MemorySecureStore backend;
  late RegPairingStore store;

  setUp(() {
    backend = _MemorySecureStore();
    store = RegPairingStore(backend);
  });

  test('未配对时 read 返回 null（不抛异常）', () async {
    expect(await store.read(), isNull);
  });

  test('write → read 往返一致', () async {
    final pairing = RegPairing.generate();
    await store.write(pairing);

    final back = await store.read();
    expect(back, isNotNull);
    expect(back!.syncId, pairing.syncId);
    expect(back.masterKey, pairing.masterKey);
  });

  test('落盘的不是明文 masterKey（走的是 TGG2 编码）', () async {
    final pairing = RegPairing.generate();
    await store.write(pairing);

    final raw = backend.data[RegPairingStore.key]!;
    expect(raw.startsWith(RegPairing.codePrefix), isTrue);
    expect(raw, isNot(contains(pairing.masterKey)));
    expect(RegPairing.decode(raw).masterKey, pairing.masterKey);
  });

  test('write 失败 → 抛 RegPairingStoreException（必须让用户知道没存上）', () async {
    backend.failWrites = true;
    await expectLater(
      store.write(RegPairing.generate()),
      throwsA(isA<RegPairingStoreException>()),
    );
  });

  test('read 后端故障 → 自愈：返回 null 并清掉坏记录', () async {
    // 先写入一份正常记录
    await store.write(RegPairing.generate());
    expect(backend.data, isNotEmpty);

    backend.failReads = true;
    expect(await store.read(), isNull);
    expect(backend.deleteCount, 1, reason: '尝试清理坏记录');
    expect(backend.data, isEmpty);
  });

  test('read 记录损坏 → 自愈：返回 null 并清理', () async {
    backend.data[RegPairingStore.key] = '这不是一个配对码';
    expect(await store.read(), isNull);
    expect(backend.data, isEmpty);
  });

  test('read 记录长度不符（被截断）→ 自愈', () async {
    backend.data[RegPairingStore.key] = RegPairing.generate()
        .encode()
        .substring(0, 40);
    expect(await store.read(), isNull);
    expect(backend.data, isEmpty);
  });

  test('clear：清空后可读到 null；失败则抛出', () async {
    await store.write(RegPairing.generate());
    await store.clear();
    expect(await store.read(), isNull);

    backend.failWrites = true;
    await expectLater(store.clear(), throwsA(isA<RegPairingStoreException>()));
  });
}
