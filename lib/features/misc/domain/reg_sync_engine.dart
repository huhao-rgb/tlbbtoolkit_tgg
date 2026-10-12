/// 卡回归 —— 云同步引擎：把「拉取 → 解密 → 本地合并 → 加密 → 回传」编排起来。
///
/// 这是阶段 2 的核心，且**与云厂商无关**：只依赖
/// [RegSyncGateway]（哑存储）与 [RegSyncCrypto]（端到端加密）两个端口，
/// 换云只需换一个网关实现。
///
/// 三条不可动摇的规则：
/// 1. **合并永远在客户端做**，服务端不参与任何业务判断；
/// 2. **解不开就不动云端**——密钥不符时若继续上传，会毁掉另一台设备的数据；
/// 3. **本地永远可用**：任何失败都只是「这次没同步成」，本地数据不受影响。
library;

import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_crypto.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

/// 一次同步的结局。
enum RegSyncStatus {
  /// 云端与本地完全一致，未产生任何写入。
  upToDate,

  /// 云端领先，本地采纳了云端内容（无需回传）。
  downloaded,

  /// 本地领先，已上传本机的新内容。
  uploaded,

  /// 双方各有一部分对方没有的内容，已合并并回传。
  merged,

  /// 云端不可用 / 密钥不符 / 持续冲突：本地已是最新可用状态，下次再试。
  unavailable,
}

/// 同步结果。
class RegSyncResult {
  const RegSyncResult({
    required this.accounts,
    required this.status,
    this.rev = 0,
    this.attempts = 1,
    this.message,
  });

  /// 合并后的**完整**记录（含墓碑）；调用方应原样落盘（见 `saveAll`）。
  final List<RegAccount> accounts;

  final RegSyncStatus status;

  /// 云端版本号（未同步成功时为已知值或 0）。
  final int rev;

  /// 实际尝试次数（>1 表示经历过版本冲突重试）。
  final int attempts;

  /// 失败原因。**仅供日志/诊断**，不要直接弹给用户看。
  final String? message;

  /// 云端是否可用（false = 本次没同步成，值得过一会儿再试）。
  bool get cloudAvailable => status != RegSyncStatus.unavailable;

  /// 本地是否发生了需要落盘的变更。
  bool get changed =>
      status == RegSyncStatus.downloaded ||
      status == RegSyncStatus.uploaded ||
      status == RegSyncStatus.merged;

  @override
  String toString() =>
      'RegSyncResult($status, rev: $rev, attempts: $attempts, '
      '${accounts.length} 条${message == null ? '' : ' · $message'})';
}

/// 同步一次卡回归数据。
///
/// - [local]：**含墓碑**的完整本地记录（`RegRepository.loadAll()`），
///   缺少墓碑会让已删除的账号被云端旧数据复活；
/// - [maxAttempts]：版本冲突时的最大尝试次数（含首次），超限则放弃本次，
///   下次同步继续（本地数据始终安全）；
/// - [nowMs]：可注入的当前时间，便于测试墓碑裁剪。
Future<RegSyncResult> syncRegAccounts({
  required RegPairing pairing,
  required List<RegAccount> local,
  required RegSyncGateway gateway,
  required RegSyncCrypto crypto,
  int maxAttempts = 3,
  int? nowMs,
}) async {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  var base = pruneRegTombstones(local, now);
  var attempts = 0;

  while (true) {
    attempts++;

    final RegRemoteSnapshot? remote;
    try {
      remote = await gateway.fetch(pairing.syncId);
    } on RegSyncUnavailableException catch (e) {
      return _unavailable(base, e.message, attempts);
    }

    // 云端还没有记录：首次配对上传（本地空则无需建记录）
    if (remote == null) {
      if (base.isEmpty) {
        return RegSyncResult(
          accounts: base,
          status: RegSyncStatus.upToDate,
          attempts: attempts,
        );
      }
      final push = await _tryPush(
        pairing: pairing,
        gateway: gateway,
        crypto: crypto,
        accounts: base,
        expectedRev: 0,
      );
      if (push.rev != null) {
        return RegSyncResult(
          accounts: base,
          status: RegSyncStatus.uploaded,
          rev: push.rev!,
          attempts: attempts,
        );
      }
      if (push.conflict && attempts < maxAttempts) continue;
      return _unavailable(
        base,
        push.message,
        attempts,
        conflict: push.conflict,
      );
    }

    // 解密云端载荷
    final List<RegAccount> remoteAccounts;
    try {
      remoteAccounts = decodeRegSyncPayload(
        await crypto.open(pairing: pairing, blob: remote.blob),
      );
    } on RegSyncCryptoException catch (e) {
      // 解不开就什么都不做：此时上传会覆盖掉另一台设备的数据。
      return _unavailable(base, e.message, attempts, rev: remote.rev);
    } on FormatException catch (e) {
      return _unavailable(
        base,
        '云端数据格式不正确：${e.message}',
        attempts,
        rev: remote.rev,
      );
    }

    final remoteReady = pruneRegTombstones(remoteAccounts, now);
    final merged = pruneRegTombstones(
      mergeRegAccounts(local: base, remote: remoteReady).merged,
      now,
    );

    final localPayload = encodeRegSyncPayload(base);
    final remotePayload = encodeRegSyncPayload(remoteReady);
    final mergedPayload = encodeRegSyncPayload(merged);

    // 云端已包含本地全部内容 → 无需回传
    if (mergedPayload == remotePayload) {
      return RegSyncResult(
        accounts: merged,
        status: mergedPayload == localPayload
            ? RegSyncStatus.upToDate
            : RegSyncStatus.downloaded,
        rev: remote.rev,
        attempts: attempts,
      );
    }

    // 本地有云端还没有的内容 → 回传（可能是「只上传」也可能是「双向合并」）
    final push = await _tryPush(
      pairing: pairing,
      gateway: gateway,
      crypto: crypto,
      accounts: merged,
      expectedRev: remote.rev,
    );
    if (push.rev != null) {
      return RegSyncResult(
        accounts: merged,
        status: mergedPayload == localPayload
            ? RegSyncStatus.uploaded
            : RegSyncStatus.merged,
        rev: push.rev!,
        attempts: attempts,
      );
    }
    if (push.conflict) {
      if (attempts >= maxAttempts) {
        return _unavailable(
          merged,
          '云端持续被其他设备更新，稍后再试',
          attempts,
          rev: remote.rev,
          conflict: true,
        );
      }
      base = merged; // 保留本轮合并成果，重拉后再合
      continue;
    }
    return _unavailable(merged, push.message, attempts, rev: remote.rev);
  }
}

/// 加密并写入云端；把可预期的失败折叠成返回值而不是异常。
Future<({int? rev, bool conflict, String? message})> _tryPush({
  required RegPairing pairing,
  required RegSyncGateway gateway,
  required RegSyncCrypto crypto,
  required List<RegAccount> accounts,
  required int expectedRev,
}) async {
  try {
    final blob = await crypto.seal(
      pairing: pairing,
      plaintext: encodeRegSyncPayload(accounts),
    );
    final rev = await gateway.push(
      syncId: pairing.syncId,
      expectedRev: expectedRev,
      blob: blob,
    );
    return (rev: rev, conflict: false, message: null);
  } on RegSyncConflictException {
    return (rev: null, conflict: true, message: null);
  } on RegSyncUnavailableException catch (e) {
    return (rev: null, conflict: false, message: e.message);
  } on RegSyncCryptoException catch (e) {
    return (rev: null, conflict: false, message: e.message);
  }
}

RegSyncResult _unavailable(
  List<RegAccount> accounts,
  String? message,
  int attempts, {
  int rev = 0,
  bool conflict = false,
}) => RegSyncResult(
  accounts: accounts,
  status: RegSyncStatus.unavailable,
  rev: rev,
  attempts: attempts,
  message: message ?? (conflict ? '云端版本冲突，稍后再试' : '云端暂不可用'),
);
