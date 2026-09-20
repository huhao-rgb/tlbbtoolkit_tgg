// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_player_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 怀旧音律播放器状态（对应原型 `bgmState` + `BGM_TRACKS` 相关逻辑）。
///
/// 与原型一致的行为约定：
/// - 播放列表只有本地导入的音乐（原型的内置五声音阶曲目未接入）；
/// - 上一首 / 下一首在列表内**环绕**（`bgmStep2`）；
/// - 循环模式开启 = 单曲循环，关闭 = 播完自动下一首（原型 `bgmAudio.onended`）；
/// - 音量 / 循环 / 上次曲目持久化（原型写 localStorage）。
///
/// [keepAlive]：播放器是全局单例，页面切换不应打断播放，
/// 也让「播完自动下一首」的订阅在顶栏重建时依然有效。

@ProviderFor(MusicPlayerController)
final musicPlayerControllerProvider = MusicPlayerControllerProvider._();

/// 怀旧音律播放器状态（对应原型 `bgmState` + `BGM_TRACKS` 相关逻辑）。
///
/// 与原型一致的行为约定：
/// - 播放列表只有本地导入的音乐（原型的内置五声音阶曲目未接入）；
/// - 上一首 / 下一首在列表内**环绕**（`bgmStep2`）；
/// - 循环模式开启 = 单曲循环，关闭 = 播完自动下一首（原型 `bgmAudio.onended`）；
/// - 音量 / 循环 / 上次曲目持久化（原型写 localStorage）。
///
/// [keepAlive]：播放器是全局单例，页面切换不应打断播放，
/// 也让「播完自动下一首」的订阅在顶栏重建时依然有效。
final class MusicPlayerControllerProvider
    extends $NotifierProvider<MusicPlayerController, MusicPlayerState> {
  /// 怀旧音律播放器状态（对应原型 `bgmState` + `BGM_TRACKS` 相关逻辑）。
  ///
  /// 与原型一致的行为约定：
  /// - 播放列表只有本地导入的音乐（原型的内置五声音阶曲目未接入）；
  /// - 上一首 / 下一首在列表内**环绕**（`bgmStep2`）；
  /// - 循环模式开启 = 单曲循环，关闭 = 播完自动下一首（原型 `bgmAudio.onended`）；
  /// - 音量 / 循环 / 上次曲目持久化（原型写 localStorage）。
  ///
  /// [keepAlive]：播放器是全局单例，页面切换不应打断播放，
  /// 也让「播完自动下一首」的订阅在顶栏重建时依然有效。
  MusicPlayerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicPlayerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicPlayerControllerHash();

  @$internal
  @override
  MusicPlayerController create() => MusicPlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicPlayerState>(value),
    );
  }
}

String _$musicPlayerControllerHash() =>
    r'f2165648f53888d08ab8a196796d0c7ee756e74f';

/// 怀旧音律播放器状态（对应原型 `bgmState` + `BGM_TRACKS` 相关逻辑）。
///
/// 与原型一致的行为约定：
/// - 播放列表只有本地导入的音乐（原型的内置五声音阶曲目未接入）；
/// - 上一首 / 下一首在列表内**环绕**（`bgmStep2`）；
/// - 循环模式开启 = 单曲循环，关闭 = 播完自动下一首（原型 `bgmAudio.onended`）；
/// - 音量 / 循环 / 上次曲目持久化（原型写 localStorage）。
///
/// [keepAlive]：播放器是全局单例，页面切换不应打断播放，
/// 也让「播完自动下一首」的订阅在顶栏重建时依然有效。

abstract class _$MusicPlayerController extends $Notifier<MusicPlayerState> {
  MusicPlayerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MusicPlayerState, MusicPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MusicPlayerState, MusicPlayerState>,
              MusicPlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
