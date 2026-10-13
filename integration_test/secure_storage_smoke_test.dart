import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tlbbtoolkit/core/storage/secure_kv_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';

/// 真实平台安全存储冒烟测试（**不需要模拟**，跑在真机 / 真桌面上）。
///
/// 单测只能验证 `RegPairingStore` 的逻辑，验证不了「这台设备/这个签名配置下
/// Keychain / Keystore 到底能不能写进去」——那正是配对凭据方案最大的未知数，
/// 所以这里用集成测试把它敲实：
///
/// ```sh
/// fvm flutter test integration_test/secure_storage_smoke_test.dart -d macos
/// fvm flutter test integration_test/secure_storage_smoke_test.dart -d <ios-simulator>
/// fvm flutter test integration_test/secure_storage_smoke_test.dart -d <android-device>
/// ```
///
/// **实测结论（2026-10）**：
/// - **iOS**（模拟器 iPhone 17 / iOS 26）：✅ 通过（写入 → 读回 → 清除全绿）；
/// - **macOS（本机 ad-hoc 签名）**：❌ 抛
///   `PlatformException(Code: -34018, A required entitlement is not present.)`。
///   根因不是沙盒开关，而是工程未配置 `DEVELOPMENT_TEAM`（`CODE_SIGN_IDENTITY = "-"`）——
///   没有团队标识就无法确定 app 的 keychain access group，`keychain-access-groups`
///   授权也加不上（加了会让 `flutter build macos` 直接构建失败，已实测）。
///   要让 macOS 同步可用，需二选一：在 Xcode 里给 Runner 配置开发团队签名
///   （并开启 Keychain Sharing 能力），或为该平台改用非安全存储的降级方案。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('配对凭据：可写入 → 可读回 → 可清除（真实安全存储）', (tester) async {
    final store = RegPairingStore(const FlutterSecureKvStore());

    // 先清干净，避免污染上一次运行
    await store.clear();
    expect(await store.read(), isNull, reason: '清理后应视为未配对');

    final pairing = RegPairing.generate();
    await store.write(pairing);

    final back = await store.read();
    expect(back, isNotNull, reason: '写入后必须能读回（否则配对等于没保存）');
    expect(back!.syncId, pairing.syncId);
    expect(back.masterKey, pairing.masterKey);

    await store.clear();
    expect(await store.read(), isNull);
  });
}
