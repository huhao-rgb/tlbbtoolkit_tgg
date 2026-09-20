// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audioplayers_music_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放引擎的依赖注入。
///
/// [keepAlive] + 惰性读取：引擎只在首次播放/暂停等操作时才被创建，
/// 避免仅构建顶栏按钮（如 widget 测试）就去触碰平台通道。

@ProviderFor(musicEngine)
final musicEngineProvider = MusicEngineProvider._();

/// 播放引擎的依赖注入。
///
/// [keepAlive] + 惰性读取：引擎只在首次播放/暂停等操作时才被创建，
/// 避免仅构建顶栏按钮（如 widget 测试）就去触碰平台通道。

final class MusicEngineProvider
    extends $FunctionalProvider<MusicEngine, MusicEngine, MusicEngine>
    with $Provider<MusicEngine> {
  /// 播放引擎的依赖注入。
  ///
  /// [keepAlive] + 惰性读取：引擎只在首次播放/暂停等操作时才被创建，
  /// 避免仅构建顶栏按钮（如 widget 测试）就去触碰平台通道。
  MusicEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicEngineHash();

  @$internal
  @override
  $ProviderElement<MusicEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MusicEngine create(Ref ref) {
    return musicEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicEngine>(value),
    );
  }
}

String _$musicEngineHash() => r'51d1db79c49b7e876c4a7e401ffda635becfd407';
