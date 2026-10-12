/// 卡回归 —— 云同步网关端口（哑存储抽象）。
///
/// 服务端**不理解任何业务语义**：它只会按 [syncId] 存取一段字符串。
/// 那段字符串是客户端加密后的密文（见 [RegSyncCrypto]），服务端拿不到明文，
/// 所以「换一家云」只是换一个实现，业务层与合并逻辑完全不动。
library;

import 'package:flutter/foundation.dart';

/// 云端快照：一段密文 + 服务端维护的单调版本号。
@immutable
class RegRemoteSnapshot {
  const RegRemoteSnapshot({required this.rev, required this.blob});

  /// 服务端版本号：每成功写入一次 +1，用于乐观并发控制。
  final int rev;

  /// 密文（客户端加密后的载荷）。
  final String blob;

  @override
  String toString() => 'RegRemoteSnapshot(rev: $rev, blob: ${blob.length}B)';
}

/// 云端暂不可用（网络异常、服务端错误、限流）。
///
/// 这是**可重试**的失败：本地数据不受影响，下次同步再试即可，
/// 调用方不应把它当成错误弹窗打扰用户。
class RegSyncUnavailableException implements Exception {
  const RegSyncUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'RegSyncUnavailableException($message)';
}

/// 版本冲突：云端已被其他设备更新（`rev` 不匹配）。
///
/// 由 [RegSyncGateway.push] 抛出，同步引擎会重新拉取 → 本地合并 → 再试。
class RegSyncConflictException implements Exception {
  const RegSyncConflictException({
    required this.expectedRev,
    required this.actualRev,
  });

  /// 本次写入所基于的版本号。
  final int expectedRev;

  /// 云端当前实际版本号。
  final int actualRev;

  @override
  String toString() =>
      'RegSyncConflictException(expected: $expectedRev, actual: $actualRev)';
}

/// 云同步网关：按 [syncId] 存取一段**密文**。
abstract interface class RegSyncGateway {
  /// 拉取快照；云端没有该记录时返回 `null`（不是异常）。
  ///
  /// 失败抛 [RegSyncUnavailableException]。
  Future<RegRemoteSnapshot?> fetch(String syncId);

  /// 写入快照，返回写入后的新版本号。
  ///
  /// [expectedRev] 为 `0` 表示「首次创建」。版本不匹配抛
  /// [RegSyncConflictException]；网络/服务失败抛 [RegSyncUnavailableException]。
  Future<int> push({
    required String syncId,
    required int expectedRev,
    required String blob,
  });

  /// 删除云端记录（解除配对时使用；记录本就不存在视为成功）。
  Future<void> remove(String syncId);
}
