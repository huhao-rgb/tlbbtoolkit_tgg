/// 数据目录的「手动同步」与「版本信号」。
///
/// 为什么需要这个文件：
/// - 目录的降级顺序是「本地缓存 → 内置 assets → null」，缓存命中就**不会**读新 assets，
///   所以改了数据、发了新包，老用户看到的仍是旧数据，除非远端也更新过。
/// - 启动时的 `refresh()` 还把新包暂存为 pending、**下次启动**才生效，
///   用户想立刻看到新数据时无从下手。
///
/// 于是提供两件事：
/// 1. [CatalogSyncController]：用户点「立即同步」→ 拉远端 → 立即 activate。
/// 2. [CatalogRevision]：一个只增不减的版本号，同步成功后 +1。各 feature 的
///    catalog provider 都 `ref.watch` 它，于是无需跨 feature import 就能整体失效重建。
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/content/catalog_providers.dart';
import 'package:tlbbtoolkit/core/content/catalog_repository.dart';
import 'package:tlbbtoolkit/core/utils/logger.dart';

part 'catalog_sync.g.dart';

/// 目录数据的版本号：同步成功后自增，用来让所有 catalog provider 重建。
///
/// 放在 core 而不是各 feature：feature 之间禁止互相 import，而「谁也不知道
/// 有哪些 feature 依赖目录」，用一个自增信号解耦。
@Riverpod(keepAlive: true)
class CatalogRevision extends _$CatalogRevision {
  @override
  int build() => 0;

  /// 通知所有依赖目录的 provider 重新读取分片。
  void bump() => state = state + 1;
}

/// 手动同步的状态机（供设置页展示）。
enum CatalogSyncStatus { idle, running, done, failed }

/// 一次同步的结果文案。
class CatalogSyncState {
  const CatalogSyncState({required this.status, required this.message});

  const CatalogSyncState.idle()
    : status = CatalogSyncStatus.idle,
      message = '从云端拉取最新的门派 / 珍兽数据';

  final CatalogSyncStatus status;

  /// 展示给用户的一句话（进行中 / 结果提示）。
  final String message;

  bool get isRunning => status == CatalogSyncStatus.running;
}

@riverpod
class CatalogSyncController extends _$CatalogSyncController {
  @override
  CatalogSyncState build() => const CatalogSyncState.idle();

  /// 拉取远端并立即生效。重复点击在 [CatalogSyncStatus.running] 时直接忽略。
  Future<void> sync() async {
    if (state.isRunning) return;
    state = const CatalogSyncState(
      status: CatalogSyncStatus.running,
      message: '正在连接云端…',
    );

    try {
      final repository = await ref.read(catalogRepositoryProvider.future);
      final outcome = await repository.syncNow();
      state = switch (outcome) {
        CatalogRefreshOutcome.skipped => const CatalogSyncState(
          status: CatalogSyncStatus.failed,
          message: '未配置云端地址，当前使用内置数据',
        ),
        CatalogRefreshOutcome.notModified => const CatalogSyncState(
          status: CatalogSyncStatus.done,
          message: '已是最新数据，无需更新',
        ),
        CatalogRefreshOutcome.updated => _bump(),
        CatalogRefreshOutcome.failed => const CatalogSyncState(
          status: CatalogSyncStatus.failed,
          message: '同步失败，请检查网络后重试',
        ),
      };
    } catch (e, s) {
      Logger.instance.error('Catalog', '手动同步失败: $e', s);
      state = const CatalogSyncState(
        status: CatalogSyncStatus.failed,
        message: '同步失败，请检查网络后重试',
      );
    }
  }

  CatalogSyncState _bump() {
    ref.read(catalogRevisionProvider.notifier).bump();
    return const CatalogSyncState(
      status: CatalogSyncStatus.done,
      message: '已更新到最新数据',
    );
  }
}
