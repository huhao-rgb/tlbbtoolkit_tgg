// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用设置状态，读写均由 [SettingsRepository] 落盘。
///
/// `@riverpod` + `extends _$AppSettingsController` 由 riverpod_generator
/// 自动生成 `appSettingsControllerProvider`。

@ProviderFor(AppSettingsController)
final appSettingsControllerProvider = AppSettingsControllerProvider._();

/// 应用设置状态，读写均由 [SettingsRepository] 落盘。
///
/// `@riverpod` + `extends _$AppSettingsController` 由 riverpod_generator
/// 自动生成 `appSettingsControllerProvider`。
final class AppSettingsControllerProvider
    extends $NotifierProvider<AppSettingsController, AppSettings> {
  /// 应用设置状态，读写均由 [SettingsRepository] 落盘。
  ///
  /// `@riverpod` + `extends _$AppSettingsController` 由 riverpod_generator
  /// 自动生成 `appSettingsControllerProvider`。
  AppSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsControllerHash();

  @$internal
  @override
  AppSettingsController create() => AppSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettings>(value),
    );
  }
}

String _$appSettingsControllerHash() =>
    r'a2e9b5ea5b7ae97e4a1db761f2862560fa3db03f';

/// 应用设置状态，读写均由 [SettingsRepository] 落盘。
///
/// `@riverpod` + `extends _$AppSettingsController` 由 riverpod_generator
/// 自动生成 `appSettingsControllerProvider`。

abstract class _$AppSettingsController extends $Notifier<AppSettings> {
  AppSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppSettings, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSettings, AppSettings>,
              AppSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 派生 provider：把设置中的主题字符串转换为 [ThemeMode]。

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

/// 派生 provider：把设置中的主题字符串转换为 [ThemeMode]。

final class ThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// 派生 provider：把设置中的主题字符串转换为 [ThemeMode]。
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return themeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeHash() => r'7899e90a04fa97d164b443c08bfc9c26c345e8e2';
