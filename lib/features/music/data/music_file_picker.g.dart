// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_file_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本地音乐选择器的依赖注入。

@ProviderFor(musicFilePicker)
final musicFilePickerProvider = MusicFilePickerProvider._();

/// 本地音乐选择器的依赖注入。

final class MusicFilePickerProvider
    extends
        $FunctionalProvider<MusicFilePicker, MusicFilePicker, MusicFilePicker>
    with $Provider<MusicFilePicker> {
  /// 本地音乐选择器的依赖注入。
  MusicFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicFilePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicFilePickerHash();

  @$internal
  @override
  $ProviderElement<MusicFilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MusicFilePicker create(Ref ref) {
    return musicFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicFilePicker>(value),
    );
  }
}

String _$musicFilePickerHash() => r'e07f2b8a3696394182178269b352bc53de534120';
