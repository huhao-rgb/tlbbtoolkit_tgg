import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_item.dart';

part 'home_providers.g.dart';

/// 首页条目列表状态。
///
/// 通过 AsyncNotifier 管理异步数据，配合 [AppAsyncView]
/// 统一展示 loading / error / data 三种状态。
///
/// `@riverpod` + `extends _$HomeItems` 由 riverpod_generator
/// 自动生成 `homeItemsProvider`。
@riverpod
class HomeItems extends _$HomeItems {
  @override
  Future<List<HomeItem>> build() {
    return ref.watch(homeRepositoryProvider).fetchHomeItems();
  }

  /// 加载失败后重试。
  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).fetchHomeItems(),
    );
  }
}
