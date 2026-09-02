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
  static const String appName = 'TLBB Toolkit';

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
}
