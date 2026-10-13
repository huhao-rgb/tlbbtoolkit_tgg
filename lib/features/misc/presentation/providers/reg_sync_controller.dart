import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_engine.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';
import 'package:tlbbtoolkit/features/misc/presentation/providers/reg_sync_providers.dart';

part 'reg_sync_controller.g.dart';

/// 云同步阶段（决定页头徽标文案与颜色）。
enum RegSyncPhase {
  /// 未配对：云同步关闭（页头徽标显示「未开启」）。
  off,

  /// 正在与云端通信。
  syncing,

  /// 已配对，且与云端一致。
  synced,

  /// 已配对，本地有变更等待推送（防抖计时中）。
  pending,

  /// 上次同步没成功（可重试）；**本地数据始终不受影响**。
  failed,
}

/// 云同步状态（UI 只读）。
class RegSyncState {
  const RegSyncState({
    this.pairing,
    this.phase = RegSyncPhase.off,
    this.lastSyncedMs,
    this.message,
    this.dataRevision = 0,
  });

  /// 本机配对凭据；null = 未配对。
  final RegPairing? pairing;

  final RegSyncPhase phase;

  /// 上次成功同步的时间（ms）。
  final int? lastSyncedMs;

  /// 失败原因；**仅供诊断**，不要直接弹给用户。
  final String? message;

  /// 每次「同步导致本地数据发生变化」时 +1。
  ///
  /// 页面据此重新加载账号列表（页面自己持有 `_accts`，同步改了存储后必须刷新）。
  final int dataRevision;

  bool get paired => pairing != null;

  RegSyncState copyWith({
    RegPairing? pairing,
    RegSyncPhase? phase,
    int? lastSyncedMs,
    String? message,
    bool clearMessage = false,
    int? dataRevision,
  }) => RegSyncState(
    pairing: pairing ?? this.pairing,
    phase: phase ?? this.phase,
    lastSyncedMs: lastSyncedMs ?? this.lastSyncedMs,
    message: clearMessage ? null : (message ?? this.message),
    dataRevision: dataRevision ?? this.dataRevision,
  );

  @override
  String toString() =>
      'RegSyncState($phase, paired: $paired, rev: $dataRevision'
      '${message == null ? '' : ' · $message'})';
}

/// 卡回归云同步控制器。
///
/// 触发时机：
/// - **启动**：读配对凭据 → 拉取一次（[build] 内异步启动）；
/// - **本地变更**：页面每次落盘后调用 [markDirty]，防抖 [_debounceDelay] 后推送；
/// - **手动**：[syncNow]。
///
/// 三条产品红线：本地永远可用；失败不抛给 UI（只改徽标状态）；未配对时零网络请求。
@riverpod
class RegSyncController extends _$RegSyncController {
  /// 本地变更合并窗口：拖拽排序/连续编辑不会每个操作都打一次接口。
  static const Duration _debounceDelay = Duration(seconds: 2);

  Timer? _debounce;
  bool _disposed = false;
  int _revision = 0;

  @override
  RegSyncState build() {
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
    });
    // 启动即尝试同步一次；失败只体现为徽标状态，不阻塞任何交互。
    unawaited(_bootstrap());
    return const RegSyncState();
  }

  Future<void> _bootstrap() async {
    final pairing = await ref.read(regPairingStoreProvider).read();
    if (_disposed || pairing == null) return;
    state = state.copyWith(pairing: pairing);
    await _sync();
  }

  /// 本地数据变更后调用（防抖后推送）。未配对时什么都不做。
  void markDirty() {
    if (_disposed || !state.paired) return;
    _debounce?.cancel();
    state = state.copyWith(phase: RegSyncPhase.pending);
    _debounce = Timer(_debounceDelay, () => unawaited(_sync()));
  }

  /// 手动「立即同步」。
  Future<void> syncNow() async {
    if (_disposed || !state.paired) return;
    _debounce?.cancel();
    await _sync();
  }

  /// 保存配对并立即同步一次。
  ///
  /// 凭据写入失败会抛 `RegPairingStoreException`（由调用方提示用户）；
  /// 同步本身失败不会抛，只把状态置为 `failed`。
  Future<void> pair(RegPairing pairing) async {
    await ref.read(regPairingStoreProvider).write(pairing);
    if (_disposed) return;
    _revision = 0;
    state = RegSyncState(pairing: pairing, phase: RegSyncPhase.pending);
    await _sync();
  }

  /// 解除配对（本机凭据删除即完成；[deleteRemote] 为 true 时顺带删云端密文）。
  Future<void> unpair({bool deleteRemote = false}) async {
    final pairing = state.pairing;
    if (pairing != null && deleteRemote) {
      try {
        await ref.read(regSyncGatewayProvider).remove(pairing.syncId);
      } on RegSyncUnavailableException {
        // 云端删不掉不影响本机解除：那边只有密文，没有明文风险。
      }
    }
    await ref.read(regPairingStoreProvider).clear();
    if (_disposed) return;
    state = const RegSyncState();
  }

  Future<void> _sync() async {
    final pairing = state.pairing;
    if (pairing == null || _disposed) return;

    state = state.copyWith(phase: RegSyncPhase.syncing, clearMessage: true);
    final repo = ref.read(regAccountRepositoryProvider);
    final result = await syncRegAccounts(
      pairing: pairing,
      local: repo.loadAll(),
      gateway: ref.read(regSyncGatewayProvider),
      crypto: ref.read(regSyncCryptoProvider),
    );
    if (_disposed) return;

    if (!result.cloudAvailable) {
      // 失败原因只进日志：徽标放不下技术细节，但真机排查时没它就只能靠猜
      // （此前它只存进 state，既不显示也不打印，等于丢失）。
      debugPrint('卡回归云同步失败：${result.message ?? '未知原因'}');
    }

    if (result.changed) {
      // 合并结果视为权威状态落盘（含墓碑），随后通知页面重新加载。
      await repo.saveAll(result.accounts, repo.load().sel);
      if (_disposed) return;
      _revision++;
    }

    state = state.copyWith(
      phase: result.cloudAvailable ? RegSyncPhase.synced : RegSyncPhase.failed,
      lastSyncedMs: result.cloudAvailable
          ? DateTime.now().millisecondsSinceEpoch
          : state.lastSyncedMs,
      message: result.message,
      dataRevision: _revision,
    );
  }
}
