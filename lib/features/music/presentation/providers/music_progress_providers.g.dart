// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_progress_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前曲目的播放进度（对应原型 `.bgm-prog` 的轮询 tick）。
///
/// 单独成 provider 而不是塞进 `MusicPlayerState`：
/// 位置每 200ms 变一次，混进播放器状态会让整个面板（含播放列表）跟着重建。
///
/// [keepAlive]：面板关掉再打开时进度接着走，不必重新等引擎上报时长。

@ProviderFor(MusicProgressController)
final musicProgressControllerProvider = MusicProgressControllerProvider._();

/// 当前曲目的播放进度（对应原型 `.bgm-prog` 的轮询 tick）。
///
/// 单独成 provider 而不是塞进 `MusicPlayerState`：
/// 位置每 200ms 变一次，混进播放器状态会让整个面板（含播放列表）跟着重建。
///
/// [keepAlive]：面板关掉再打开时进度接着走，不必重新等引擎上报时长。
final class MusicProgressControllerProvider
    extends $NotifierProvider<MusicProgressController, MusicProgress> {
  /// 当前曲目的播放进度（对应原型 `.bgm-prog` 的轮询 tick）。
  ///
  /// 单独成 provider 而不是塞进 `MusicPlayerState`：
  /// 位置每 200ms 变一次，混进播放器状态会让整个面板（含播放列表）跟着重建。
  ///
  /// [keepAlive]：面板关掉再打开时进度接着走，不必重新等引擎上报时长。
  MusicProgressControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicProgressControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicProgressControllerHash();

  @$internal
  @override
  MusicProgressController create() => MusicProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicProgress>(value),
    );
  }
}

String _$musicProgressControllerHash() =>
    r'b53ae47b2b60f6510d6a72c1757985ca69cd4e33';

/// 当前曲目的播放进度（对应原型 `.bgm-prog` 的轮询 tick）。
///
/// 单独成 provider 而不是塞进 `MusicPlayerState`：
/// 位置每 200ms 变一次，混进播放器状态会让整个面板（含播放列表）跟着重建。
///
/// [keepAlive]：面板关掉再打开时进度接着走，不必重新等引擎上报时长。

abstract class _$MusicProgressController extends $Notifier<MusicProgress> {
  MusicProgress build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MusicProgress, MusicProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MusicProgress, MusicProgress>,
              MusicProgress,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
