import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_memory.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_crypto.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_engine.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

/// 现实量级的时间基准（避免合成时间戳被「墓碑 180 天保留期」误裁）。
const int t0 = 1700000000000;
const int tNow = t0 + 1000;

RegAccount acct(
  String id, {
  String name = '甲',
  int lv = 89,
  List<RegRun> runs = const [],
  int updatedAt = t0 + 10,
  int? deletedAt,
}) => RegAccount(
  id: id,
  name: name,
  lv: lv,
  sectKey: 'xiaoyao',
  runs: runs,
  updatedAt: updatedAt,
  deletedAt: deletedAt,
);

/// 第 [n] 轮回归（起点互不相同，便于断言并集顺序）。
RegRun run(int n) => RegRun(startMs: t0 + n * 1000, endMs: t0 + n * 1000 + 500);

/// 一台设备的最小上下文：配对 + 云端（内存网关）+ 加密实现。
class _Harness {
  static const RegSyncCrypto crypto = RegSyncCryptoAesGcm();

  final RegPairing pairing = RegPairing.generate();
  final RegSyncGatewayMemory gw = RegSyncGatewayMemory();

  /// 注入引擎的「当前时间」；置 null 则用真实时钟（与仓储集成时用）。
  int? nowMs = tNow;

  Future<RegSyncResult> sync(
    List<RegAccount> local, {
    RegSyncGateway? gateway,
  }) => syncRegAccounts(
    pairing: pairing,
    local: local,
    gateway: gateway ?? gw,
    crypto: crypto,
    nowMs: nowMs,
  );
}

/// 网关包装：在「下一次 push 之前」插入一次外部写入，用来制造版本冲突。
class _RacingGateway implements RegSyncGateway {
  _RacingGateway(this.inner);

  final RegSyncGateway inner;
  Future<void> Function()? beforeNextPush;

  @override
  Future<RegRemoteSnapshot?> fetch(String syncId) => inner.fetch(syncId);

  @override
  Future<int> push({
    required String syncId,
    required int expectedRev,
    required String blob,
  }) async {
    final race = beforeNextPush;
    if (race != null) {
      beforeNextPush = null;
      await race();
    }
    return inner.push(syncId: syncId, expectedRev: expectedRev, blob: blob);
  }

  @override
  Future<void> remove(String syncId) => inner.remove(syncId);
}

void main() {
  group('协议工具', () {
    test('云同步载荷：往返一致、携带墓碑、坏数据抛 FormatException', () {
      final accounts = [
        acct('a1', name: '甲', runs: [run(1), run(2)]),
        acct('a2', name: '乙', deletedAt: t0 + 40, updatedAt: t0 + 40),
      ];
      final text = encodeRegSyncPayload(accounts);
      final back = decodeRegSyncPayload(text);

      expect(back, hasLength(2));
      expect(back[0].name, '甲');
      expect(back[0].runs, [run(1), run(2)]);
      expect(back[1].isDeleted, isTrue);
      expect(back[1].deletedAt, t0 + 40);
      expect(encodeRegSyncPayload(back), text, reason: '编解码幂等');

      expect(() => decodeRegSyncPayload('{"foo":1}'), throwsFormatException);
      expect(() => decodeRegSyncPayload('not json'), throwsFormatException);
    });

    test('云同步载荷：顺序规范化 —— 与输入顺序无关，且不改动调用方的列表', () {
      // 引擎用「载荷文本相等」判断是否需要回传，而合并结果会保留各自的
      // local 顺序；若载荷随顺序而变，两端内容一致却会互相反复回传。
      final a = acct('b1', name: '乙');
      final b = acct('a1', name: '甲');
      final c = acct('c1', name: '丙');

      expect(
        encodeRegSyncPayload([a, b, c]),
        encodeRegSyncPayload([c, a, b]),
        reason: '同一组账号应编码出完全相同的文本',
      );

      final input = [a, b, c];
      encodeRegSyncPayload(input);
      expect(input.map((x) => x.id).toList(), [
        'b1',
        'a1',
        'c1',
      ], reason: '编码不得就地排序调用方的列表');
    });

    test('墓碑裁剪：过期丢弃、未过期保留、存活记录永不动（边界含等号）', () {
      final now = t0 + kRegTombstoneTtlMs;
      final kept = pruneRegTombstones([
        acct('live', name: '甲'),
        acct('fresh', name: '乙', deletedAt: now - 1000, updatedAt: now - 1000),
        acct(
          'expired',
          name: '丙',
          deletedAt: now - kRegTombstoneTtlMs,
          updatedAt: now - kRegTombstoneTtlMs,
        ),
      ], now);

      expect(kept.map((a) => a.id), ['live', 'fresh']);
    });
  });

  group('合并对称性（脚本靠载荷字节相等判断「是否已同步」）', () {
    test('去重取定规范 id：镜像方向必须得到同一个 id 与同一份载荷', () {
      // 历史数据的现实场景：同名同门派的账号在两端各自新增过，
      // 早期版本用毫秒时间戳做 id → 两端 id 不同。若各自「保留本机 id」，
      // 两端合并出的载荷永远不同 → 每次同步都各白写一次云端（无限往复）。
      final onA = acct('aaaa0000000000000000000000000001', name: '逍遥生');
      final onB = acct('bbbb0000000000000000000000000002', name: '逍遥生');

      final fromA = mergeRegAccounts(
        local: [onA],
        remote: [onB],
        canonicalizeIds: true,
      ).merged;
      final fromB = mergeRegAccounts(
        local: [onB],
        remote: [onA],
        canonicalizeIds: true,
      ).merged;

      expect(fromA, hasLength(1));
      expect(fromB, hasLength(1));
      expect(fromA.single.id, fromB.single.id, reason: '两端必须收敛到同一个 id');
      expect(fromA.single.id, onA.id, reason: '取字典序较小者');
      expect(
        encodeRegSyncPayload(fromA),
        encodeRegSyncPayload(fromB),
        reason: '载荷必须逐字节一致，否则永远到不了 upToDate',
      );
    });

    test('本机 id 较大时会被换成规范 id，且确实写回', () {
      final big = acct('bbbb0000000000000000000000000002', name: '逍遥生');
      final small = acct('aaaa0000000000000000000000000001', name: '逍遥生');

      final res = mergeRegAccounts(
        local: [big],
        remote: [small],
        canonicalizeIds: true,
      );
      expect(res.merged.single.id, small.id);
      expect(res.updated, 1, reason: 'id 变化必须真的写回，否则本机永远坚持自己的 id，往复依旧');
    });

    test('导入路径（默认关闭规范化）不得改动本机 id', () {
      final localAcct = acct('a1', name: '已有号');
      final incoming = acct('00000000000000000000000000000001', name: '已有号');

      final res = mergeRegAccounts(local: [localAcct], remote: [incoming]);
      expect(res.merged.single.id, 'a1', reason: '导入是本地动作，不该换掉本机 id');
      expect(res.updated, 0);
      expect(res.skipped, 1);
    });

    test('墓碑同样规范化（墓碑 id 不一致一样会往复）', () {
      final tombA = acct(
        'aaaa0000000000000000000000000001',
        name: '逍遥生',
        deletedAt: t0 + 100,
        updatedAt: t0 + 100,
      );
      final tombB = acct(
        'bbbb0000000000000000000000000002',
        name: '逍遥生',
        deletedAt: t0 + 100,
        updatedAt: t0 + 100,
      );

      final fromA = mergeRegAccounts(
        local: [tombA],
        remote: [tombB],
        canonicalizeIds: true,
      ).merged;
      final fromB = mergeRegAccounts(
        local: [tombB],
        remote: [tombA],
        canonicalizeIds: true,
      ).merged;

      expect(fromA.single.isDeleted, isTrue);
      expect(fromA.single.id, fromB.single.id);
      expect(encodeRegSyncPayload(fromA), encodeRegSyncPayload(fromB));
    });

    test('复活路径：回归轮次取并集，且镜像方向结果一致', () {
      final tomb = acct(
        'aaaa0000000000000000000000000001',
        name: '逍遥生',
        runs: [run(1)],
        deletedAt: t0 + 50,
        updatedAt: t0 + 50,
      );
      final live = acct(
        'bbbb0000000000000000000000000002',
        name: '逍遥生',
        runs: [run(2)],
        updatedAt: t0 + 90,
      );

      final fromTomb = mergeRegAccounts(
        local: [tomb],
        remote: [live],
        canonicalizeIds: true,
      ).merged;
      final fromLive = mergeRegAccounts(
        local: [live],
        remote: [tomb],
        canonicalizeIds: true,
      ).merged;

      expect(fromTomb.single.isDeleted, isFalse, reason: '更晚的存活记录应复活账号');
      expect(fromTomb.single.runs, [run(1), run(2)], reason: '轮次取并集，不得丢');
      expect(fromLive.single.runs, [
        run(1),
        run(2),
      ], reason: '镜像方向同样取并集（否则两端载荷不一致）');
      expect(encodeRegSyncPayload(fromTomb), encodeRegSyncPayload(fromLive));
    });
  });

  test('首次同步：上传本机数据，云端只存密文', () async {
    final h = _Harness();
    final res = await h.sync([acct('a1', name: '逍遥生', updatedAt: t0 + 10)]);

    expect(res.status, RegSyncStatus.uploaded);
    expect(res.rev, 1);
    expect(res.attempts, 1);

    final blob = h.gw.rawBlob(h.pairing.syncId)!;
    expect(blob, isNot(contains('逍遥生')));
    expect(blob, isNot(contains('xiaoyao')));

    final payload = decodeRegSyncPayload(
      await _Harness.crypto.open(pairing: h.pairing, blob: blob),
    );
    expect(payload.single.name, '逍遥生');
  });

  test('本机为空时不建云端记录（避免产生空记录）', () async {
    final h = _Harness();
    final res = await h.sync(const []);
    expect(res.status, RegSyncStatus.upToDate);
    expect(h.gw.recordCount, 0);
    expect(h.gw.pushCount, 0);
  });

  test('第二台设备：只下载并采纳，不回传（云端 rev 不变）', () async {
    final h = _Harness();
    await h.sync([acct('a1', name: '甲', updatedAt: t0 + 10)]);
    expect(h.gw.pushCount, 1);

    final res = await h.sync(const []);
    expect(res.status, RegSyncStatus.downloaded);
    expect(res.rev, 1, reason: '只下载不该产生写入');
    expect(h.gw.pushCount, 1);
    expect(res.accounts.single.name, '甲');
  });

  test('双向各有新内容 → 合并回传，两端收敛且重复同步零写入', () async {
    final h = _Harness();
    final r1 = run(1), r2 = run(2), r3 = run(3);

    var res = await h.sync([
      acct('a1', name: '甲', runs: [r1]),
    ]);
    expect(res.status, RegSyncStatus.uploaded);
    var a = res.accounts;

    res = await h.sync(const []);
    var b = res.accounts;
    expect(b.single.runs, [r1]);

    // A 本机又完成一轮（本地领先）→ 只上传
    a = [
      b.single.copyWith(runs: [r1, r2], updatedAt: t0 + 20),
    ];
    res = await h.sync(a);
    expect(res.status, RegSyncStatus.uploaded);
    a = res.accounts;

    // B 也完成一轮 + 新增账号 → 双方内容不同 → 合并回传
    b = [
      b.single.copyWith(runs: [r1, r3], updatedAt: t0 + 30),
      acct('b1', name: '乙', lv: 95, updatedAt: t0 + 30),
    ];
    res = await h.sync(b);
    expect(res.status, RegSyncStatus.merged);
    b = res.accounts;

    // A 拉取 → 收敛（回归记录取并集，一个轮次都不丢）
    res = await h.sync(a);
    expect(res.status, RegSyncStatus.downloaded);
    a = res.accounts;
    expect(a, hasLength(2));
    expect(a.firstWhere((x) => x.name == '甲').runs, [r1, r2, r3]);
    expect(a.map((x) => x.name).toSet(), {'甲', '乙'});
    expect(encodeRegSyncPayload(a), encodeRegSyncPayload(b));

    // 已完全一致 → 不产生任何写入
    final pushes = h.gw.pushCount;
    res = await h.sync(a);
    expect(res.status, RegSyncStatus.upToDate);
    expect(h.gw.pushCount, pushes);
    expect(res.accounts, hasLength(2));
  });

  test('删除传播：墓碑经云端同步到其他设备，旧副本无法复活账号', () async {
    final h = _Harness();
    var res = await h.sync([acct('a1', name: '甲'), acct('a2', name: '乙')]);
    expect(res.status, RegSyncStatus.uploaded);
    var a = res.accounts;

    res = await h.sync(const []);
    var b = res.accounts;
    expect(b, hasLength(2));

    // A 删掉 乙 → 本地留墓碑
    a = [a[0], a[1].copyWith(deletedAt: t0 + 40, updatedAt: t0 + 40)];
    res = await h.sync(a);
    expect(res.status, RegSyncStatus.uploaded);
    a = res.accounts;

    // B 同步 → 也删掉 乙
    res = await h.sync(b);
    b = res.accounts;
    expect(res.status, RegSyncStatus.downloaded);
    expect(b.where((x) => !x.isDeleted).map((x) => x.name), ['甲']);
    expect(b.where((x) => x.isDeleted), hasLength(1));

    // 「删除后再没联过网」的第三台设备拿旧副本同步 → 不能复活 乙
    final stale = [acct('a1', name: '甲'), acct('a2', name: '乙')];
    res = await h.sync(stale);
    expect(res.status, RegSyncStatus.downloaded);
    expect(res.accounts.where((x) => !x.isDeleted).map((x) => x.name), ['甲']);
    expect(res.accounts.where((x) => x.isDeleted), hasLength(1));
  });

  test('配对码不匹配：不写云端（绝不覆盖另一台设备的数据）', () async {
    final h = _Harness();
    await h.sync([acct('a1', name: '甲')]);
    final before = h.gw.rawBlob(h.pairing.syncId);
    final pushes = h.gw.pushCount;

    // 同一个 syncId（能定位到记录）但 masterKey 不同 → 解不开
    final wrong = RegPairing(
      syncId: h.pairing.syncId,
      masterKey: RegPairing.generate().masterKey,
    );
    final res = await syncRegAccounts(
      pairing: wrong,
      local: [acct('zz', name: '入侵者')],
      gateway: h.gw,
      crypto: _Harness.crypto,
      nowMs: tNow,
    );

    expect(res.status, RegSyncStatus.unavailable);
    expect(res.cloudAvailable, isFalse);
    expect(res.message, contains('不一致'));
    expect(h.gw.rawBlob(h.pairing.syncId), before);
    expect(h.gw.pushCount, pushes);
    expect(res.accounts.single.name, '入侵者'); // 本地数据不受影响
  });

  test('版本冲突：重拉 → 本地合并 → 重试成功，双方内容都不丢', () async {
    final h = _Harness();
    final r1 = run(1), r2 = run(2), r3 = run(3);

    final first = await h.sync([
      acct('a1', name: '甲', runs: [r1]),
    ]);
    expect(first.rev, 1);

    final racing = _RacingGateway(h.gw)
      ..beforeNextPush = () async {
        // 另一台设备在本机「即将写入」的瞬间抢先写入（rev 1 → 2）
        await syncRegAccounts(
          pairing: h.pairing,
          local: [
            first.accounts.single.copyWith(runs: [r1, r3], updatedAt: t0 + 30),
          ],
          gateway: h.gw,
          crypto: _Harness.crypto,
          nowMs: tNow,
        );
      };

    final out = await h.sync([
      first.accounts.single.copyWith(runs: [r1, r2], updatedAt: t0 + 20),
    ], gateway: racing);

    expect(out.status, RegSyncStatus.merged);
    expect(out.attempts, 2, reason: '冲突后重试了一次');
    expect(out.accounts.single.runs, [r1, r2, r3]);
    expect(out.rev, 3);
  });

  test('离线：本地数据原样返回，状态为 unavailable（可重试）', () async {
    final h = _Harness();
    h.gw.offline = true;

    final res = await h.sync([acct('a1', name: '甲')]);
    expect(res.status, RegSyncStatus.unavailable);
    expect(res.changed, isFalse);
    expect(res.accounts.single.name, '甲');
    expect(h.gw.pushCount, 0);

    // 恢复联网后继续可用
    h.gw.offline = false;
    expect(
      (await h.sync([acct('a1', name: '甲')])).status,
      RegSyncStatus.uploaded,
    );
  });

  test('与仓储集成：loadAll 提供含墓碑的基准，saveAll 落盘合并结果', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = RegRepository(LocalStorage(prefs));
    final h = _Harness()..nowMs = null; // 与仓储共用真实时钟

    await repo.save([
      RegAccount(id: 'a1', name: '甲', lv: 89, sectKey: 'xiaoyao'),
      RegAccount(id: 'a2', name: '乙', lv: 90, sectKey: 'xiaoyao'),
    ], null);
    expect(repo.loadAll(), hasLength(2));

    var res = await h.sync(repo.loadAll());
    expect(res.status, RegSyncStatus.uploaded);
    await repo.saveAll(res.accounts, null);

    // 本机删除 乙 → 墓碑只留在 localAll，不出现在 UI 列表里
    await repo.save([repo.load().accts.firstWhere((a) => a.name == '甲')], null);
    expect(repo.load().accts, hasLength(1));
    expect(repo.loadAll().where((a) => a.isDeleted), hasLength(1));

    // 同步把「删除」推到云端
    res = await h.sync(repo.loadAll());
    expect(res.changed, isTrue);
    await repo.saveAll(res.accounts, null);

    // 「删除前的老设备」拿旧副本同步 → 不复活 乙
    final stale = [
      repo.load().accts.single,
      RegAccount(
        id: 'a2',
        name: '乙',
        lv: 90,
        sectKey: 'xiaoyao',
        updatedAt: t0,
      ),
    ];
    res = await h.sync(stale);
    expect(res.status, RegSyncStatus.downloaded);
    await repo.saveAll(res.accounts, null);

    expect(repo.load().accts.map((a) => a.name), ['甲']);
    expect(repo.loadAll().where((a) => a.isDeleted), hasLength(1));
  });
}
