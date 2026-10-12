import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

/// [RegSyncGateway] 的内存实现。
///
/// 用途有二：
/// - **单测**：不碰网络就能跑完整的同步协议（含版本冲突、离线）；
/// - **占位**：阶段 2.2 接入真实云之前，DI 里先注入它，UI 可以照常工作。
///
/// 语义刻意与真实云端一致：`rev` 从 1 开始、`expectedRev = 0` 表示新建、
/// 版本不匹配抛 [RegSyncConflictException]、网络问题抛
/// [RegSyncUnavailableException]。
class RegSyncGatewayMemory implements RegSyncGateway {
  final Map<String, RegRemoteSnapshot> _store = {};

  /// 置为 `true` 模拟断网（所有请求抛 [RegSyncUnavailableException]）。
  bool offline = false;

  /// 请求计数（断言「未产生冗余写入」时用）。
  int fetchCount = 0;
  int pushCount = 0;

  /// 当前云端记录数（诊断用）。
  int get recordCount => _store.length;

  /// 直接读取云端密文（测试断言「云端只有密文」时用）。
  String? rawBlob(String syncId) => _store[syncId]?.blob;

  @override
  Future<RegRemoteSnapshot?> fetch(String syncId) async {
    if (offline) throw const RegSyncUnavailableException('离线');
    fetchCount++;
    return _store[syncId];
  }

  @override
  Future<int> push({
    required String syncId,
    required int expectedRev,
    required String blob,
  }) async {
    if (offline) throw const RegSyncUnavailableException('离线');
    pushCount++;
    final current = _store[syncId];
    if (expectedRev != (current?.rev ?? 0)) {
      throw RegSyncConflictException(
        expectedRev: expectedRev,
        actualRev: current?.rev ?? 0,
      );
    }
    final next = expectedRev + 1;
    _store[syncId] = RegRemoteSnapshot(rev: next, blob: blob);
    return next;
  }

  @override
  Future<void> remove(String syncId) async {
    if (offline) throw const RegSyncUnavailableException('离线');
    _store.remove(syncId);
  }
}
