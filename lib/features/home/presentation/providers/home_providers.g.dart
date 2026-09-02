// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 首页条目列表状态。
///
/// 通过 AsyncNotifier 管理异步数据，配合 [AppAsyncView]
/// 统一展示 loading / error / data 三种状态。
///
/// `@riverpod` + `extends _$HomeItems` 由 riverpod_generator
/// 自动生成 `homeItemsProvider`。

@ProviderFor(HomeItems)
final homeItemsProvider = HomeItemsProvider._();

/// 首页条目列表状态。
///
/// 通过 AsyncNotifier 管理异步数据，配合 [AppAsyncView]
/// 统一展示 loading / error / data 三种状态。
///
/// `@riverpod` + `extends _$HomeItems` 由 riverpod_generator
/// 自动生成 `homeItemsProvider`。
final class HomeItemsProvider
    extends $AsyncNotifierProvider<HomeItems, List<HomeItem>> {
  /// 首页条目列表状态。
  ///
  /// 通过 AsyncNotifier 管理异步数据，配合 [AppAsyncView]
  /// 统一展示 loading / error / data 三种状态。
  ///
  /// `@riverpod` + `extends _$HomeItems` 由 riverpod_generator
  /// 自动生成 `homeItemsProvider`。
  HomeItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeItemsHash();

  @$internal
  @override
  HomeItems create() => HomeItems();
}

String _$homeItemsHash() => r'f579080ff0095536133417dfb0e530cd52234f3a';

/// 首页条目列表状态。
///
/// 通过 AsyncNotifier 管理异步数据，配合 [AppAsyncView]
/// 统一展示 loading / error / data 三种状态。
///
/// `@riverpod` + `extends _$HomeItems` 由 riverpod_generator
/// 自动生成 `homeItemsProvider`。

abstract class _$HomeItems extends $AsyncNotifier<List<HomeItem>> {
  FutureOr<List<HomeItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<HomeItem>>, List<HomeItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<HomeItem>>, List<HomeItem>>,
              AsyncValue<List<HomeItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
