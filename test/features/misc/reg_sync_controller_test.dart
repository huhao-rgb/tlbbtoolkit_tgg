import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/core/storage/secure_kv_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_memory.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_crypto.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_engine.dart';
import 'package:tlbbtoolkit/features/misc/presentation/providers/reg_sync_controller.dart';
import 'package:tlbbtoolkit/features/misc/presentation/providers/reg_sync_providers.dart';

/// 内存版安全存储（测试不碰平台通道）。
class MemorySecureStore implements SecureKvStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

const RegSyncCrypto _crypto = RegSyncCryptoAesGcm();

/// 冲干净微任务队列（真实定时器环境下代替 tester.pump）。
Future<void> flush() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class Harness {
  Harness(this.container, this.secure, this.gateway, this.repo);

  final ProviderContainer container;
  final MemorySecureStore secure;
  final RegSyncGatewayMemory gateway;
  final RegRepository repo;

  final List<void Function()> _closers = [];
  bool _listened = false;

  RegSyncState get state => container.read(regSyncControllerProvider);

  RegSyncController get controller =>
      container.read(regSyncControllerProvider.notifier);

  /// 装常驻订阅，两个作用：
  /// 1. Riverpod 会为「只被 read 过、随后无订阅」的 provider 安排一个 0 时长
  ///    销毁定时器，用例结束时会报 pending timer；
  /// 2. 无订阅时 `read` 会重建控制器、丢掉状态。
  ///
  /// 可延迟调用：需要在「首次读取控制器」之前预置安全存储 / 云端数据时用。
  void listen() {
    if (_listened) return;
    _listened = true;
    _closers
      ..add(container.listen(regAccountRepositoryProvider, (_, _) {}).close)
      ..add(container.listen(regPairingStoreProvider, (_, _) {}).close)
      ..add(container.listen(regSyncGatewayProvider, (_, _) {}).close)
      ..add(container.listen(regSyncConfigProvider, (_, _) {}).close)
      ..add(container.listen(regSyncControllerProvider, (_, _) {}).close);
  }

  void dispose() {
    for (final close in _closers) {
      close();
    }
    container.dispose();
  }
}

Future<Harness> makeHarness({bool listen = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final secure = MemorySecureStore();
  final gateway = RegSyncGatewayMemory();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      secureKvStoreProvider.overrideWithValue(secure),
      regSyncGatewayProvider.overrideWithValue(gateway),
      regSyncConfigProvider.overrideWithValue((
        enabled: true,
        baseUrl: 'https://sync.example.com',
        path: '/reg',
      )),
    ],
  );
  final h = Harness(
    container,
    secure,
    gateway,
    container.read(regAccountRepositoryProvider),
  );
  if (listen) h.listen();
  addTearDown(h.dispose);
  return h;
}

RegAccount acct(String id, {String name = '甲', List<RegRun> runs = const []}) =>
    RegAccount(
      id: id,
      name: name,
      lv: 89,
      sectKey: 'xiaoyao',
      runs: runs,
      updatedAt: 1700000000000,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('未配对：状态 off，且**零网络请求**', () async {
    final h = await makeHarness();

    expect(h.state.phase, RegSyncPhase.off);
    expect(h.state.paired, isFalse);
    await flush();

    // 未配对时本地变更也不该打接口
    h.controller.markDirty();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(h.gateway.fetchCount, 0);
    expect(h.gateway.pushCount, 0);
    expect(h.state.phase, RegSyncPhase.off);
  });

  test('配对：立刻上传本机数据，云端只有密文', () async {
    final h = await makeHarness();

    await h.repo.save([acct('a1', name: '逍遥生')], null);
    final pairing = RegPairing.generate();
    await h.controller.pair(pairing);
    await flush();

    expect(h.state.phase, RegSyncPhase.synced);
    expect(h.state.paired, isTrue);
    expect(h.state.lastSyncedMs, isNotNull);

    final blob = h.gateway.rawBlob(pairing.syncId)!;
    expect(blob, isNot(contains('逍遥生')));
    expect(
      decodeRegSyncPayload(await _crypto.open(pairing: pairing, blob: blob))
          .single
          .name,
      '逍遥生',
    );
    // 凭据进了安全存储
    expect(await RegPairingStore(h.secure).read(), pairing);
  });

  test('配对本机为空：不建云端空记录，状态仍为 synced', () async {
    final h = await makeHarness();

    await h.controller.pair(RegPairing.generate());
    await flush();

    expect(h.gateway.recordCount, 0);
    expect(h.state.phase, RegSyncPhase.synced);
  });

  test('本地变更：防抖窗口内多次改动只推送一次', () async {
    final h = await makeHarness();

    await h.repo.save([acct('a1')], null);
    await h.controller.pair(RegPairing.generate());
    final pushes = h.gateway.pushCount;

    // 模拟连续两笔本地改动（拖拽排序 / 连续编辑）
    await h.repo.save([
      acct('a1', runs: [RegRun(startMs: 1, endMs: 2)]),
    ], null);
    h.controller.markDirty();
    expect(h.state.phase, RegSyncPhase.pending);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(h.gateway.pushCount, pushes, reason: '还在防抖窗口内');

    // 第二笔改动把窗口重置
    await h.repo.save([
      acct('a1', runs: [RegRun(startMs: 1, endMs: 2)]),
      acct('a2', name: '乙'),
    ], null);
    h.controller.markDirty();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(h.gateway.pushCount, pushes, reason: '窗口被重置，仍不该推送');

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(h.gateway.pushCount, pushes + 1, reason: '窗口结束后只推一次');
    expect(h.state.phase, RegSyncPhase.synced);
  });

  test('云端有新数据：拉取 → 写回本地 → dataRevision +1（页面据此刷新）', () async {
    final h = await makeHarness();

    await h.repo.save([acct('a1', name: '甲')], null);
    final pairing = RegPairing.generate();
    await h.controller.pair(pairing);
    final rev0 = h.state.dataRevision;

    // 「另一台设备」把它的账号推到同一个云端
    await syncRegAccounts(
      pairing: pairing,
      local: [acct('b1', name: '乙')],
      gateway: h.gateway,
      crypto: _crypto,
    );

    await h.controller.syncNow();
    await flush();

    expect(h.state.dataRevision, rev0 + 1);
    expect(h.state.phase, RegSyncPhase.synced);
    expect(h.repo.load().accts.map((a) => a.name).toSet(), {
      '甲',
      '乙',
    }, reason: '拉到的内容必须落盘，否则页面看不到');
  });

  test('启动：已有配对凭据 → 自动同步一次（重装 App 的场景）', () async {
    // 延迟订阅：先预置「安全存储里的凭据」与「云端已有数据」，
    // 再首次读取控制器，才是真实的冷启动顺序。
    final h = await makeHarness(listen: false);

    final pairing = RegPairing.generate();
    await syncRegAccounts(
      pairing: pairing,
      local: [acct('a1', name: '甲')],
      gateway: h.gateway,
      crypto: _crypto,
    );
    // 本机数据为空（相当于刚重装），但安全存储里已有配对凭据
    h.secure.data[RegPairingStore.key] = pairing.encode();

    h.listen(); // 首次读取控制器 → 触发 build 内的 bootstrap
    await flush();

    expect(h.state.phase, RegSyncPhase.synced);
    expect(h.repo.load().accts.map((a) => a.name), ['甲']);
  });

  test('云端不可用：状态 failed 且带原因，本地数据不受影响', () async {
    final h = await makeHarness();

    await h.repo.save([acct('a1', name: '甲')], null);
    await h.controller.pair(RegPairing.generate());
    h.gateway.offline = true;

    await h.controller.syncNow();
    await flush();

    expect(h.state.phase, RegSyncPhase.failed);
    expect(h.state.message, isNotNull);
    expect(h.repo.load().accts, hasLength(1));
    expect(h.state.paired, isTrue, reason: '失败不应丢掉配对');

    // 恢复联网后手动重试即可恢复
    h.gateway.offline = false;
    await h.controller.syncNow();
    expect(h.state.phase, RegSyncPhase.synced);
  });

  test('配对凭据写入失败：抛 RegPairingStoreException，状态不进入配对', () async {
    final h = await makeHarness();

    final failing = FailingSecureStore();
    final container = ProviderContainer(
      overrides: [
        secureKvStoreProvider.overrideWithValue(failing),
        regSyncGatewayProvider.overrideWithValue(h.gateway),
        regSyncConfigProvider.overrideWithValue((
          enabled: true,
          baseUrl: 'https://sync.example.com',
          path: '/reg',
        )),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    final subs = [
      container.listen(secureKvStoreProvider, (_, _) {}),
      container.listen(regSyncControllerProvider, (_, _) {}),
    ];
    addTearDown(() {
      for (final s in subs) {
        s.close();
      }
      container.dispose();
    });

    await expectLater(
      container
          .read(regSyncControllerProvider.notifier)
          .pair(RegPairing.generate()),
      throwsA(isA<RegPairingStoreException>()),
    );
    expect(container.read(regSyncControllerProvider).paired, isFalse);
  });

  test('解除同步：凭据清除、云端记录删除、状态回到 off', () async {
    final h = await makeHarness();

    await h.repo.save([acct('a1')], null);
    await h.controller.pair(RegPairing.generate());
    expect(h.gateway.recordCount, 1);

    await h.controller.unpair(deleteRemote: true);
    await flush();

    expect(h.state.phase, RegSyncPhase.off);
    expect(h.state.paired, isFalse);
    expect(await RegPairingStore(h.secure).read(), isNull);
    expect(h.gateway.recordCount, 0);
    expect(h.repo.load().accts, hasLength(1), reason: '解除同步不该删本地数据');
  });
}

/// 写入必失败的安全存储（模拟 Web 非 HTTPS / Linux 缺 libsecret）。
class FailingSecureStore implements SecureKvStore {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('secure backend down');

  @override
  Future<void> delete(String key) async => throw StateError('down');
}
