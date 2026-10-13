// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reg_sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 卡回归数据仓储。
///
/// 页面与同步控制器共用这一份（同一 `LocalStorage` 底层），
/// 避免两处各建实例后状态各说各话。

@ProviderFor(regAccountRepository)
final regAccountRepositoryProvider = RegAccountRepositoryProvider._();

/// 卡回归数据仓储。
///
/// 页面与同步控制器共用这一份（同一 `LocalStorage` 底层），
/// 避免两处各建实例后状态各说各话。

final class RegAccountRepositoryProvider
    extends $FunctionalProvider<RegRepository, RegRepository, RegRepository>
    with $Provider<RegRepository> {
  /// 卡回归数据仓储。
  ///
  /// 页面与同步控制器共用这一份（同一 `LocalStorage` 底层），
  /// 避免两处各建实例后状态各说各话。
  RegAccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regAccountRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regAccountRepositoryHash();

  @$internal
  @override
  $ProviderElement<RegRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegRepository create(Ref ref) {
    return regAccountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegRepository>(value),
    );
  }
}

String _$regAccountRepositoryHash() =>
    r'3dd22bdff22b99346ac2f0435a70830864af4ae5';

/// 配对凭据存储（Keychain / Keystore，**不明文落盘**）。

@ProviderFor(regPairingStore)
final regPairingStoreProvider = RegPairingStoreProvider._();

/// 配对凭据存储（Keychain / Keystore，**不明文落盘**）。

final class RegPairingStoreProvider
    extends
        $FunctionalProvider<RegPairingStore, RegPairingStore, RegPairingStore>
    with $Provider<RegPairingStore> {
  /// 配对凭据存储（Keychain / Keystore，**不明文落盘**）。
  RegPairingStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regPairingStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regPairingStoreHash();

  @$internal
  @override
  $ProviderElement<RegPairingStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegPairingStore create(Ref ref) {
    return regPairingStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegPairingStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegPairingStore>(value),
    );
  }
}

String _$regPairingStoreHash() => r'ca8a34fdb8b4f513e37ed40406c706841f96d006';

/// 端到端加密实现（密钥只在本机派生，云端只见密文）。

@ProviderFor(regSyncCrypto)
final regSyncCryptoProvider = RegSyncCryptoProvider._();

/// 端到端加密实现（密钥只在本机派生，云端只见密文）。

final class RegSyncCryptoProvider
    extends $FunctionalProvider<RegSyncCrypto, RegSyncCrypto, RegSyncCrypto>
    with $Provider<RegSyncCrypto> {
  /// 端到端加密实现（密钥只在本机派生，云端只见密文）。
  RegSyncCryptoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regSyncCryptoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regSyncCryptoHash();

  @$internal
  @override
  $ProviderElement<RegSyncCrypto> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegSyncCrypto create(Ref ref) {
    return regSyncCrypto(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegSyncCrypto value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegSyncCrypto>(value),
    );
  }
}

String _$regSyncCryptoHash() => r'd840b1d794ba0d19490158b482598741710129ea';

@ProviderFor(regSyncConfig)
final regSyncConfigProvider = RegSyncConfigProvider._();

final class RegSyncConfigProvider
    extends $FunctionalProvider<RegSyncConfig, RegSyncConfig, RegSyncConfig>
    with $Provider<RegSyncConfig> {
  RegSyncConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regSyncConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regSyncConfigHash();

  @$internal
  @override
  $ProviderElement<RegSyncConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegSyncConfig create(Ref ref) {
    return regSyncConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegSyncConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegSyncConfig>(value),
    );
  }
}

String _$regSyncConfigHash() => r'10da0202857b4356a05e7780eadb2d40ebef64b9';

/// 云同步网关。
///
/// 注入 `--dart-define=SYNC_BASE_URL=https://<envId>.service.tcloudbase.com`
/// 时走真实云端；未注入则给「未配置」占位（状态一律 `unavailable`），
/// 卡回归功能照常离线可用。

@ProviderFor(regSyncGateway)
final regSyncGatewayProvider = RegSyncGatewayProvider._();

/// 云同步网关。
///
/// 注入 `--dart-define=SYNC_BASE_URL=https://<envId>.service.tcloudbase.com`
/// 时走真实云端；未注入则给「未配置」占位（状态一律 `unavailable`），
/// 卡回归功能照常离线可用。

final class RegSyncGatewayProvider
    extends $FunctionalProvider<RegSyncGateway, RegSyncGateway, RegSyncGateway>
    with $Provider<RegSyncGateway> {
  /// 云同步网关。
  ///
  /// 注入 `--dart-define=SYNC_BASE_URL=https://<envId>.service.tcloudbase.com`
  /// 时走真实云端；未注入则给「未配置」占位（状态一律 `unavailable`），
  /// 卡回归功能照常离线可用。
  RegSyncGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regSyncGatewayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regSyncGatewayHash();

  @$internal
  @override
  $ProviderElement<RegSyncGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegSyncGateway create(Ref ref) {
    return regSyncGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegSyncGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegSyncGateway>(value),
    );
  }
}

String _$regSyncGatewayHash() => r'862d3b504ed67772dc89f2e6862b39cb49a24f17';
