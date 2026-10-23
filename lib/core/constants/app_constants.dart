/// 应用级全局常量。
///
/// 这里的常量不依赖任何业务层，可被任意 feature 引用。
/// 支持通过 `--dart-define` 在构建时注入，例如：
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=https://api.example.com \
///             --dart-define=USE_LOCAL_DATA_SOURCE=false
/// ```
abstract final class AppConstants {
  const AppConstants._();

  /// 应用展示名称。
  static const String appName = '天工阁';

  /// 接口根地址，通过 `--dart-define=API_BASE_URL=...` 注入。
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  /// 是否使用本地模拟数据源（脚手架演示用）。
  /// 开发阶段默认 `true`，接入真实后端时改为 `false`。
  static const bool useLocalDataSource = bool.fromEnvironment(
    'USE_LOCAL_DATA_SOURCE',
    defaultValue: true,
  );

  /// 云同步接口根地址（腾讯云开发 CloudBase 的 HTTP 访问服务域名，
  /// 形如 `https://<envId>.service.tcloudbase.com`），通过
  /// `--dart-define=SYNC_BASE_URL=...` 注入（本地见 `.vscode/launch.json`，
  /// CI 见仓库变量 `vars.SYNC_BASE_URL`）。
  ///
  /// **留空 = 未启用云同步**：卡回归功能照常离线可用，云同步入口隐藏。
  /// 「是否已配置 + 斜杠容错」的统一判定见 `regSyncConfigProvider`。
  static const String syncBaseUrl = String.fromEnvironment('SYNC_BASE_URL');

  /// 云同步接口路径，需与控制台里 HTTP 访问服务配置的路径一致。
  static const String syncPath = String.fromEnvironment(
    'SYNC_PATH',
    defaultValue: '/reg',
  );

  /// 数据目录（catalog）接口根地址，通过 `--dart-define=CATALOG_BASE_URL=...`
  /// 注入；与云同步共用同一个 CloudBase 环境域名。
  ///
  /// **留空 = 未启用远端更新**：App 只用内置 `assets/catalog/` 数据，
  /// 不产生任何网络请求。
  static const String catalogBaseUrl = String.fromEnvironment(
    'CATALOG_BASE_URL',
  );

  /// 数据目录路由前缀，需与控制台 HTTP 访问服务里配置的路径一致。
  static const String catalogPath = String.fromEnvironment(
    'CATALOG_PATH',
    defaultValue: '/catalog',
  );
}
