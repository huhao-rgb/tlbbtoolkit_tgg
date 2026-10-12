/// 卡回归 —— 端到端加密端口。
///
/// 密钥完全由 [RegPairing.masterKey] 在本机派生，**从不上传**；
/// 云端只见密文，所以：拖库/内鬼拿到的只是乱码，合规压力也降到最低
/// （服务端不持有任何用户数据）。代价是配对码丢失 = 数据不可恢复。
library;

import 'package:tlbbtoolkit/features/misc/domain/reg_pairing.dart';

/// 密文无法还原（密钥不匹配，或密文被篡改/损坏）。
///
/// 这是**不可重试**的失败：调用方必须放弃本次同步且不得覆盖云端数据，
/// 否则会把另一台设备的数据抹掉。
class RegSyncCryptoException implements Exception {
  const RegSyncCryptoException(this.message);

  final String message;

  @override
  String toString() => 'RegSyncCryptoException($message)';
}

/// 对称加密端口（认证加密 AEAD：机密性 + 完整性）。
abstract interface class RegSyncCrypto {
  /// 加密 [plaintext]，返回可安全上传的密文文本。
  Future<String> seal({required RegPairing pairing, required String plaintext});

  /// 解密 [blob]；密钥不符或密文被篡改时抛 [RegSyncCryptoException]。
  Future<String> open({required RegPairing pairing, required String blob});
}
