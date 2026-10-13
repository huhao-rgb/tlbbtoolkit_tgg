/// 卡回归云同步 —— **真实链路**端到端测试。
///
/// 与 `test/features/misc/reg_sync_*_test.dart` 的区别：那些用内存网关验证逻辑，
/// 本文件走**真实 dio → 真实云函数 → 真实 PostgreSQL**，只有加解密（真 AES-GCM）
/// 与合并（真引擎）在本地完成。
///
/// 它覆盖的是单测**无法证明**的部分：网络契约、服务端 CAS 语义、真实 409、
/// 密文在链路上确实是密文、以及两台设备最终是否真的收敛。
///
/// **默认跳过**：只有注入 `SYNC_BASE_URL` 时才执行，因此 CI 与离线开发不受影响，
/// 也不会往真实环境写垃圾数据。运行：
///
/// ```sh
/// fvm flutter test test/features/misc/reg_sync_e2e_test.dart \
///   --dart-define=SYNC_BASE_URL=https://<envId>.service.tcloudbase.com
/// ```
///
/// 每个用例都用**随机 syncId**（等价于云端新建一条记录），并在结束时删掉该记录，
/// 不触碰既有数据。
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/constants/app_constants.dart';
import 'package:tlbbtoolkit/core/network/api_client.dart';
import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_remote.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_engine.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

/// 真实云端根地址；为空 = 未配置 → 整个文件跳过。
const String _baseUrl = AppConstants.syncBaseUrl;

const String _skipReason =
    '未注入 SYNC_BASE_URL，跳过真实链路测试。运行：'
    'fvm flutter test test/features/misc/reg_sync_e2e_test.dart '
    '--dart-define=SYNC_BASE_URL=https://<envId>.service.tcloudbase.com';

/// 单台「虚拟设备」的本地存储。
///
/// 用内存 map 而非 `SharedPreferences`：后者在本进程里是单例，
/// 两台「设备」会共用一份数据，那就测不出同步效果了。
class _DeviceStorage extends LocalStorage {
  _DeviceStorage(this._mem, SharedPreferences prefs) : super(prefs);

  final Map<String, String> _mem;

  @override
  Map<String, dynamic>? getJson(String key) {
    final raw = _mem[key];
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async =>
      _mem[key] = jsonEncode(value);

  @override
  Future<void> remove(String key) async => _mem.remove(key);
}

/// 一台虚拟设备：独立本地存储 + 独立 dio。
class _Device {
  _Device._({
    required this.label,
    required this.pairing,
    required this.storage,
    required this.repo,
    required this.dio,
  }) {
    gateway = RegSyncGatewayRemote(dio, path: AppConstants.syncPath);
  }

  /// 新建一台设备（独立 storage、独立 dio）。
  factory _Device.create({
    required String label,
    required RegPairing pairing,
    required SharedPreferences prefs,
  }) {
    final storage = _DeviceStorage({}, prefs);
    return _Device._(
      label: label,
      pairing: pairing,
      storage: storage,
      repo: RegRepository(storage),
      dio: ApiClient.createSyncDio(_baseUrl),
    );
  }

  final String label;
  final _DeviceStorage storage;
  final RegRepository repo;
  final Dio dio;
  final RegPairing pairing;

  /// 可替换成装饰器，用于确定性地制造「拉取后被抢先写入」的竞态。
  late RegSyncGateway gateway;

  /// 存活账号（UI 视角）。
  List<RegAccount> get live => repo.load().accts;

  /// 含墓碑的完整记录（同步视角）。
  List<RegAccount> get all => repo.loadAll();

  /// 走与线上控制器**完全相同**的路径：`loadAll` → 引擎 → `saveAll`。
  Future<RegSyncResult> sync() async {
    final result = await syncRegAccounts(
      pairing: pairing,
      local: repo.loadAll(),
      gateway: gateway,
      crypto: const RegSyncCryptoAesGcm(),
    );
    if (result.changed) {
      await repo.saveAll(result.accounts, repo.load().sel);
    }
    return result;
  }

  /// 新增账号（等价于页面上录入一条）。
  Future<void> add(RegAccount account) =>
      repo.save([...live, account], account.id);

  /// 修改账号（等价于页面上编辑）。
  Future<void> edit(String id, RegAccount Function(RegAccount) update) =>
      repo.save([
        for (final a in live) a.id == id ? update(a) : a,
      ], repo.load().sel);

  /// 删除账号（仓储会自行生成墓碑，这是跨端删除的关键）。
  Future<void> delete(String id) => repo.save([
    for (final a in live)
      if (a.id != id) a,
  ], repo.load().sel);

  void dispose() => dio.close();
}

/// 「第一次拉取返回陈旧快照，之后正常」的装饰器。
///
/// 真实网络上很难稳定制造「拉取与写入之间被别的设备抢先」的竞态，
/// 用它可**确定性地**触发服务端真实 409，从而验证引擎的重试与合并。
class _StaleFirstFetchGateway implements RegSyncGateway {
  _StaleFirstFetchGateway(this._inner, this._stale);

  final RegSyncGateway _inner;
  final RegRemoteSnapshot _stale;

  int fetchCount = 0;

  @override
  Future<RegRemoteSnapshot?> fetch(String syncId) async {
    fetchCount++;
    return fetchCount == 1 ? _stale : _inner.fetch(syncId);
  }

  @override
  Future<int> push({
    required String syncId,
    required int expectedRev,
    required String blob,
  }) => _inner.push(syncId: syncId, expectedRev: expectedRev, blob: blob);

  @override
  Future<void> remove(String syncId) => _inner.remove(syncId);
}

RegAccount _account(String name, {required int lv, required String sect}) =>
    RegAccount(id: newRegAccountId(), name: name, lv: lv, sectKey: sect);

/// 跨设备比对用的指纹（按 id 取「名字/等级/轮次」，不依赖列表顺序）。
Map<String, String> _fingerprint(List<RegAccount> accts) => {
  for (final a in accts) a.id: '${a.name}/${a.lv}/${a.runs.length}',
};

/// 直接读云端原始记录（绕过客户端封装，用于验证「链路上确实是密文」）。
Future<Map<String, dynamic>?> _rawCloudSnapshot(Dio dio, String syncId) async {
  final res = await dio.get<dynamic>(
    AppConstants.syncPath,
    queryParameters: {'code': syncId},
    options: Options(validateStatus: (_) => true),
  );
  if (res.statusCode != 200) return null;
  return Map<String, dynamic>.from(res.data as Map);
}

/// 建一对已配对的设备（B 相当于「扫了 A 的配对码」），结束时删掉云端记录。
Future<void> _withPairedDevices(
  Future<void> Function(_Device a, _Device b, Dio raw, RegPairing pairing) body,
) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = ApiClient.createSyncDio(_baseUrl);
  final pairing = RegPairing.generate();
  final a = _Device.create(label: 'A', pairing: pairing, prefs: prefs);
  final b = _Device.create(label: 'B', pairing: pairing, prefs: prefs);

  try {
    await body(a, b, raw, pairing);
  } finally {
    try {
      await raw.delete<dynamic>(
        AppConstants.syncPath,
        queryParameters: {'code': pairing.syncId},
        options: Options(validateStatus: (_) => true),
      );
    } catch (e) {
      // ignore: avoid_print
      print('清理云端记录失败（不影响用例结论）：$e');
    }
    a.dispose();
    b.dispose();
    raw.close();
  }
}

/// 真实网络往返较慢，给每个用例放宽超时（`group` 本身不接受 timeout）。
void _e2eTest(String name, Future<void> Function() body) =>
    test(name, body, timeout: const Timeout(Duration(minutes: 3)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final configured = _baseUrl.isNotEmpty;

  group('卡回归云同步 · 真实链路（$_baseUrl）', () {
    setUp(() {
      // ⚠️ 关键一步：TestWidgetsFlutterBinding 会把 HttpClient 换成「一律返回
      // HTTP 400 且不发真实请求」的 mock（flutter_test 的既定行为）。本文件要打
      // 真实云端，必须把它还原，否则所有请求都会莫名 400。
      HttpOverrides.global = null;

      // _DeviceStorage 需要 SharedPreferences 实例（仅为满足父类构造），
      // 真正的数据在各自的内存 map 里。
      SharedPreferences.setMockInitialValues({});
    });

    _e2eTest('端到端加密：云端只有密文，链路上拿不到任何明文', () async {
      await _withPairedDevices((a, _, raw, pairing) async {
        final account = _account('加密验证号', lv: 99, sect: 'xiaoyao');
        await a.add(account);

        final result = await a.sync();
        expect(result.status, RegSyncStatus.uploaded);
        expect(result.rev, 1);

        final remote = await _rawCloudSnapshot(raw, pairing.syncId);
        expect(remote, isNotNull, reason: '同步后云端应有记录');
        final blob = remote!['blob'] as String;

        // 1) 明文关键字一个都不该出现
        for (final secret in [
          account.name,
          account.sectKey,
          account.id,
          'accts',
          'updatedAt',
        ]) {
          expect(
            blob.contains(secret),
            isFalse,
            reason: '云端密文里不应出现明文「$secret」',
          );
        }
        // 2) 密钥与 syncId 也不该出现
        expect(blob.contains(pairing.masterKey), isFalse);
        expect(blob.contains(pairing.syncId), isFalse);

        // 3) 不是 JSON（能 jsonDecode 就说明根本没加密）
        expect(
          () => jsonDecode(blob),
          throwsA(isA<FormatException>()),
          reason: '载荷应是无结构密文，不该是明文 JSON',
        );

        // 4) 确实是我们的密文格式：Base64Url 可解，长度 ≥ nonce(12)+tag(16)
        expect(
          base64Url.decode(blob).length,
          greaterThanOrEqualTo(28),
          reason: '应含 nonce 与 GCM tag',
        );
      });
    });

    _e2eTest('首次配对：A 上传 → B 拉取 → 再同步不产生写入', () async {
      await _withPairedDevices((a, b, raw, pairing) async {
        await a.add(_account('甲', lv: 88, sect: 'wudang'));
        await a.add(_account('乙', lv: 77, sect: 'emei'));

        final pushed = await a.sync();
        expect(pushed.status, RegSyncStatus.uploaded);
        expect(pushed.rev, 1);

        final pulled = await b.sync();
        expect(pulled.status, RegSyncStatus.downloaded);
        expect(pulled.rev, 1);
        expect(_fingerprint(b.live), _fingerprint(a.live));

        final idle = await b.sync();
        expect(idle.status, RegSyncStatus.upToDate);
        expect(idle.rev, 1);
        expect(
          (await _rawCloudSnapshot(raw, pairing.syncId))!['rev'],
          1,
          reason: '无变化时不得推进版本',
        );
      });
    });

    _e2eTest('双向合并：两台各有对方没有的数据 → 收敛到并集', () async {
      await _withPairedDevices((a, b, raw, pairing) async {
        await a.add(_account('共享', lv: 90, sect: 'shaolin'));
        await a.sync();

        await b.sync(); // B 拿到「共享」
        await a.add(_account('只在A', lv: 71, sect: 'tianshan'));
        await b.add(_account('只在B', lv: 72, sect: 'xingxiu'));

        final bPush = await b.sync();
        expect(bPush.status, RegSyncStatus.uploaded);

        // A 本地有「只在A」、云端有「只在B」→ 真正的双向合并
        final aMerge = await a.sync();
        expect(aMerge.status, RegSyncStatus.merged);
        expect(aMerge.attempts, 1);

        // 内容已一致 → 第三台视角不该再有写入（回归防护：曾因载荷顺序
        // 随「谁先合并」而变，导致两端每次同步都各白写一次、rev 无限增长）
        final bPull = await b.sync();
        expect(bPull.status, RegSyncStatus.downloaded);

        expect(a.live, hasLength(3));
        expect(a.live.map((x) => x.name).toSet(), {'共享', '只在A', '只在B'});
        expect(_fingerprint(b.live), _fingerprint(a.live));

        // 稳态：双方都 upToDate，且云端 rev 不再增长
        final settledRev = (await _rawCloudSnapshot(
          raw,
          pairing.syncId,
        ))!['rev'];
        expect((await a.sync()).status, RegSyncStatus.upToDate);
        expect((await b.sync()).status, RegSyncStatus.upToDate);
        expect(
          (await _rawCloudSnapshot(raw, pairing.syncId))!['rev'],
          settledRev,
          reason: '两端内容一致后，任何一端都不应再写云端',
        );
      });
    });

    _e2eTest('真实 409：服务端 CAS 拒绝陈旧 rev，且不覆盖既有数据', () async {
      await _withPairedDevices((a, b, raw, pairing) async {
        final acc = _account('CAS', lv: 60, sect: 'gaibang');
        await a.add(acc);
        await a.sync(); // rev 1
        await a.edit(acc.id, (x) => x.copyWith(lv: 61));
        await a.sync(); // rev 2

        // 用早已过期的 rev 直接写：必须被服务端拒绝
        await expectLater(
          b.gateway.push(
            syncId: pairing.syncId,
            expectedRev: 1,
            blob: 'stale-write-should-be-rejected',
          ),
          throwsA(
            isA<RegSyncConflictException>()
                .having((e) => e.expectedRev, 'expectedRev', 1)
                .having((e) => e.actualRev, 'actualRev', 2),
          ),
        );

        final remote = await _rawCloudSnapshot(raw, pairing.syncId);
        expect(remote!['rev'], 2, reason: '被拒的写入不得推进版本');
        expect(
          remote['blob'],
          isNot('stale-write-should-be-rejected'),
          reason: '被拒的写入不得覆盖云端数据',
        );
      });
    });

    _e2eTest('引擎重试：拉取后被抢先写入 → 真实 409 → 重拉合并后成功', () async {
      await _withPairedDevices((a, b, raw, pairing) async {
        final acc = _account('竞态', lv: 50, sect: 'mingjiao');
        await a.add(acc);
        await a.sync(); // rev 1
        await b.sync(); // B 拿到 rev 1

        // 捕获一个「陈旧快照」，稍后让 B 的第一跳看到它
        final stale = await b.gateway.fetch(pairing.syncId);
        expect(stale, isNotNull);

        // A 抢先写入 → 云端 rev 2
        await a.edit(acc.id, (x) => x.copyWith(lv: 51));
        await a.sync();
        expect((await _rawCloudSnapshot(raw, pairing.syncId))!['rev'], 2);

        // B 基于陈旧快照写入：首次 push 必然 409，引擎应重拉后成功
        await b.edit(acc.id, (x) => x.copyWith(lv: 52));
        final decorator = _StaleFirstFetchGateway(b.gateway, stale!);
        b.gateway = decorator;

        final result = await b.sync();
        expect(
          decorator.fetchCount,
          greaterThanOrEqualTo(2),
          reason: '冲突后应重新拉取',
        );
        expect(result.attempts, greaterThanOrEqualTo(2));
        // B 的合并结果就等于它的本地内容（B 的编辑更晚，LWW 后 B 全胜），
        // 所以这里体现为「上传」而不是「双向合并」
        expect(result.status, RegSyncStatus.uploaded);

        // 双方收敛，且 B 更晚的编辑生效（LWW）
        await a.sync();
        expect(_fingerprint(b.live), _fingerprint(a.live));
        expect(a.live.single.lv, 52);

        // 稳态：重试过程结束后两端不再互相写
        expect((await a.sync()).status, RegSyncStatus.upToDate);
        expect((await b.sync()).status, RegSyncStatus.upToDate);
      });
    });

    _e2eTest('删除靠墓碑传播：另一台同步后消失，且不会被云端旧数据复活', () async {
      await _withPairedDevices((a, b, _, _) async {
        final keep = _account('保留', lv: 80, sect: 'tangmen');
        final drop = _account('待删', lv: 81, sect: 'tangmen');
        await a.add(keep);
        await a.add(drop);
        await a.sync();
        await b.sync();
        expect(b.live, hasLength(2));

        await a.delete(drop.id);
        await a.sync();

        final bPull = await b.sync();
        expect(
          bPull.status,
          anyOf(RegSyncStatus.downloaded, RegSyncStatus.merged),
        );
        expect(b.live.map((x) => x.name), ['保留']);

        // 再同步几次也不该复活（墓碑参与合并）
        await b.sync();
        await b.sync();
        expect(b.live.map((x) => x.name), ['保留']);
        expect(_fingerprint(b.live), _fingerprint(a.live));
      });
    });

    _e2eTest('密钥不符：拒绝上传，绝不破坏云端既有数据', () async {
      await _withPairedDevices((a, _, raw, pairing) async {
        await a.add(_account('原始', lv: 40, sect: 'shenlong'));
        await a.sync(); // rev 1
        final before = await _rawCloudSnapshot(raw, pairing.syncId);

        // 同 syncId、不同 masterKey 的「冒牌设备」
        final prefs = await SharedPreferences.getInstance();
        final impostor = _Device.create(
          label: 'C',
          pairing: RegPairing(
            syncId: pairing.syncId,
            masterKey: RegPairing.generate().masterKey,
          ),
          prefs: prefs,
        );
        try {
          await impostor.add(_account('冒牌写入', lv: 1, sect: 'xingxiu'));
          final blocked = await impostor.sync();
          expect(blocked.status, RegSyncStatus.unavailable);
          expect(blocked.cloudAvailable, isFalse);
        } finally {
          impostor.dispose();
        }

        final after = await _rawCloudSnapshot(raw, pairing.syncId);
        expect(after!['rev'], before!['rev'], reason: '解不开就不得写云端');
        expect(after['blob'], before['blob'], reason: '云端密文必须逐字节不变');

        // 原设备不受影响
        final stillFine = await a.sync();
        expect(stillFine.status, RegSyncStatus.upToDate);
        expect(a.live.single.name, '原始');
      });
    });

    _e2eTest('历史数据：同一账号两端 id 不同 → 收敛到同一 id 且不再往复写', () async {
      await _withPairedDevices((a, b, raw, pairing) async {
        // 老版本 App 用毫秒时间戳做 id：同一个账号在两台设备各录一次，
        // id 就会不同 —— 这正是「保留本机 id」会导致无限往复的场景。
        const idOnA = '1759000000002';
        const idOnB = '1759000000001'; // 字典序较小者，应成为规范 id
        await a.add(
          RegAccount(id: idOnA, name: '老数据', lv: 80, sectKey: 'xiaoyao'),
        );
        await a.sync();

        await b.add(
          RegAccount(id: idOnB, name: '老数据', lv: 80, sectKey: 'xiaoyao'),
        );
        await b.sync();

        // A 拉取后应把本机 id 换成规范 id（不再是「坚持本机 id」）
        final aPull = await a.sync();
        expect(aPull.status, RegSyncStatus.downloaded);
        expect(a.live, hasLength(1), reason: '同一逻辑账号不得变成两条');
        expect(a.live.single.id, idOnB);
        expect(b.live.single.id, idOnB);

        // 收敛后必须彻底安静：两端都 upToDate，云端 rev 不再增长
        final settledRev = (await _rawCloudSnapshot(
          raw,
          pairing.syncId,
        ))!['rev'];
        expect((await a.sync()).status, RegSyncStatus.upToDate);
        expect((await b.sync()).status, RegSyncStatus.upToDate);
        expect(
          (await _rawCloudSnapshot(raw, pairing.syncId))!['rev'],
          settledRev,
          reason: '修复前这里会一直涨（两端互相反复回传）',
        );
      });
    });

    _e2eTest('空本地 + 云端有数据 → 拉取而非清空；本地为空时不建垃圾记录', () async {
      await _withPairedDevices((a, b, raw, pairing) async {
        await a.add(_account('云端已有', lv: 70, sect: 'kunlun'));
        await a.sync();

        // B 本地为空：应下载，而不是把云端那份删掉
        final bPull = await b.sync();
        expect(bPull.status, RegSyncStatus.downloaded);
        expect(bPull.rev, 1);
        expect(b.live.single.name, '云端已有');
        expect((await _rawCloudSnapshot(raw, pairing.syncId))!['rev'], 1);

        // 全新配对 + 空本地：不应在云端建一条空记录
        final prefs = await SharedPreferences.getInstance();
        final emptyPairing = RegPairing.generate();
        final empty = _Device.create(
          label: 'D',
          pairing: emptyPairing,
          prefs: prefs,
        );
        try {
          final res = await empty.sync();
          expect(res.status, RegSyncStatus.upToDate);
          expect(res.rev, 0);
          expect(res.cloudAvailable, isTrue, reason: '这不是失败，是无需建记录');
          expect(
            await _rawCloudSnapshot(raw, emptyPairing.syncId),
            isNull,
            reason: '本地为空时不应创建云端记录',
          );
        } finally {
          empty.dispose();
        }
      });
    });
  }, skip: configured ? null : _skipReason);
}
