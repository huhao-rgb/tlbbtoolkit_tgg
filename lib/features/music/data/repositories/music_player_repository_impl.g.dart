// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_player_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放器仓储的依赖注入。

@ProviderFor(musicPlayerRepository)
final musicPlayerRepositoryProvider = MusicPlayerRepositoryProvider._();

/// 播放器仓储的依赖注入。

final class MusicPlayerRepositoryProvider
    extends
        $FunctionalProvider<
          MusicPlayerRepository,
          MusicPlayerRepository,
          MusicPlayerRepository
        >
    with $Provider<MusicPlayerRepository> {
  /// 播放器仓储的依赖注入。
  MusicPlayerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicPlayerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicPlayerRepositoryHash();

  @$internal
  @override
  $ProviderElement<MusicPlayerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MusicPlayerRepository create(Ref ref) {
    return musicPlayerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicPlayerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicPlayerRepository>(value),
    );
  }
}

String _$musicPlayerRepositoryHash() =>
    r'4904bd1bf0cfbb2732f66f3c6ebd72f0178d6aad';
