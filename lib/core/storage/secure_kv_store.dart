import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 平台安全存储的最小端口（Keychain / Keystore / libsecret / 凭据管理器）。
///
/// 抽成接口有两个理由：
/// - 单测可以注入内存实现，不必碰平台通道；
/// - 将来换实现（如自研加密 + `LocalStorage`）只改一个文件。
abstract interface class SecureKvStore {
  /// 读取；键不存在返回 `null`。后端不可用时应抛异常（由调用方决定成败策略）。
  Future<String?> read(String key);

  /// 写入（覆盖同键）。
  Future<void> write(String key, String value);

  /// 删除（键不存在视为成功）。
  Future<void> delete(String key);
}

/// [SecureKvStore] 的默认实现，落到 `flutter_secure_storage`。
///
/// 各平台后端：iOS/macOS Keychain、Android Keystore（RSA-OAEP 包裹 + AES-GCM）、
/// Windows 凭据管理器、Linux libsecret、Web WebCrypto。
///
/// 平台注意事项（**均已实测**）：
/// - **macOS 本机 ad-hoc 签名下不可用**：会抛
///   `PlatformException(Code: -34018, A required entitlement is not present.)`。
///   根因是工程未配置 `DEVELOPMENT_TEAM`（`CODE_SIGN_IDENTITY = "-"`）→
///   系统无法确定 app 的 keychain access group；而声明 `keychain-access-groups`
///   授权又要求开发证书（实测会让 `flutter build macos` **直接构建失败**），
///   所以本项目**不加**该授权。要在 macOS 上启用云同步，需在 Xcode 里给 Runner
///   配置开发团队签名并开启 Keychain Sharing 能力；关沙盒**不解决**（同样 -34018）。
///   验证脚本见 `integration_test/secure_storage_smoke_test.dart`；
/// - **iOS**：模拟器实测通过，无需额外配置；
/// - **Android**：Keystore 密钥不参与 Google Drive 备份，换机恢复后旧密文无法解开
///   （调用方按「读失败 = 未配对」自愈即可，见 `RegPairingStore.read`）；
/// - **Linux**：构建机需 `libsecret-1-dev`，运行机需 `libsecret-1-0`；
/// - **Web**：需 HTTPS（或 localhost）才有 `crypto.subtle`。
class FlutterSecureKvStore implements SecureKvStore {
  const FlutterSecureKvStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
