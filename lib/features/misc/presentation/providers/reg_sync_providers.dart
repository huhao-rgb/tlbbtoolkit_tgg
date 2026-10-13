import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/constants/app_constants.dart';
import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/core/network/api_client.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_disabled.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_remote.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_crypto.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

part 'reg_sync_providers.g.dart';

/// 卡回归数据仓储。
///
/// 页面与同步控制器共用这一份（同一 `LocalStorage` 底层），
/// 避免两处各建实例后状态各说各话。
@riverpod
RegRepository regAccountRepository(Ref ref) =>
    RegRepository(ref.watch(localStorageProvider));

/// 配对凭据存储（Keychain / Keystore，**不明文落盘**）。
@riverpod
RegPairingStore regPairingStore(Ref ref) =>
    RegPairingStore(ref.watch(secureKvStoreProvider));

/// 端到端加密实现（密钥只在本机派生，云端只见密文）。
@riverpod
RegSyncCrypto regSyncCrypto(Ref ref) => const RegSyncCryptoAesGcm();

/// 云同步配置（来自 `--dart-define`，见 `AppConstants.sync*`）。
///
/// 抽成 provider 是为了让 UI 逻辑（徽标是否可见、弹窗默认落在哪个 tab）
/// 与真实构建开关解耦，测试里可直接 override。
typedef RegSyncConfig = ({bool enabled, String baseUrl, String path});

/// 归一化两个 `--dart-define` 拼出的配置，是「云同步是否配置」的唯一判定点。
///
/// 两个值都是人工填写的（本地 `.vscode/launch.json` 或 CI 仓库变量），
/// 粘贴时容易带上多余斜杠；而网关是按 `baseUrl + path` **直接字符串拼接**的，
/// `https://host/` + `/reg` 会拼成 `https://host//reg` 而静默 404。
RegSyncConfig normalizeRegSyncConfig({
  required String baseUrl,
  required String path,
}) {
  final cleanBaseUrl = _trimSlashes(baseUrl);
  final cleanPath = _trimSlashes(path);
  return (
    enabled: cleanBaseUrl.isNotEmpty,
    baseUrl: cleanBaseUrl,
    // 空路径保持为空（不再补 `/`），以免改变「显式传空路径」的原有语义
    path: cleanPath.isEmpty ? '' : '/$cleanPath',
  );
}

String _trimSlashes(String value) =>
    value.trim().replaceAll(RegExp(r'^/+|/+$'), '');

@riverpod
RegSyncConfig regSyncConfig(Ref ref) => normalizeRegSyncConfig(
  baseUrl: AppConstants.syncBaseUrl,
  path: AppConstants.syncPath,
);

/// 云同步网关。
///
/// 注入 `--dart-define=SYNC_BASE_URL=https://<envId>.service.tcloudbase.com`
/// 时走真实云端；未注入则给「未配置」占位（状态一律 `unavailable`），
/// 卡回归功能照常离线可用。
///
/// **必须 `keepAlive`**：`@riverpod` 默认 autoDispose，无人订阅时会被销毁，
/// 而销毁会触发下面的 `dio.close()`；此时**进行中的请求会抛**
/// `StateError("Can't establish connection after the adapter was closed.")`
/// —— 实测就是这样让真机上的每次同步都失败的（单测用的是内存网关，测不出来）。
/// 网关本就是长生命周期资源，长驻还能复用连接池。
@Riverpod(keepAlive: true)
RegSyncGateway regSyncGateway(Ref ref) {
  final config = ref.watch(regSyncConfigProvider);
  if (!config.enabled) return const RegSyncGatewayDisabled();
  final dio = ApiClient.createSyncDio(config.baseUrl);
  ref.onDispose(dio.close);
  return RegSyncGatewayRemote(dio, path: config.path);
}
