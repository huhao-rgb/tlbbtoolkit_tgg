// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_file_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 音频落盘器的依赖注入。

@ProviderFor(musicFileStore)
final musicFileStoreProvider = MusicFileStoreProvider._();

/// 音频落盘器的依赖注入。

final class MusicFileStoreProvider
    extends $FunctionalProvider<MusicFileStore, MusicFileStore, MusicFileStore>
    with $Provider<MusicFileStore> {
  /// 音频落盘器的依赖注入。
  MusicFileStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicFileStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicFileStoreHash();

  @$internal
  @override
  $ProviderElement<MusicFileStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MusicFileStore create(Ref ref) {
    return musicFileStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicFileStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicFileStore>(value),
    );
  }
}

String _$musicFileStoreHash() => r'e106df5250f29527be3f71731dcc7fdb9ebb4d5b';
