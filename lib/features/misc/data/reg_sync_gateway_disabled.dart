import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

/// 未配置云端时的占位网关：**永远报「不可用」，绝不假装同步成功**。
///
/// `SYNC_BASE_URL` 没注入时 DI 注入它，好处是上层（引擎 / UI）行为与
/// 「云端暂时连不上」完全一致——状态是 `unavailable`、消息是「未配置云同步」，
/// 不会出现空指针或「静默跳过但界面显示已同步」这两种更难查的问题。
class RegSyncGatewayDisabled implements RegSyncGateway {
  const RegSyncGatewayDisabled();

  /// 展示给用户/日志的原因。
  static const String message = '未配置云同步（缺少 SYNC_BASE_URL）';

  @override
  Future<RegRemoteSnapshot?> fetch(String syncId) async =>
      throw const RegSyncUnavailableException(message);

  @override
  Future<int> push({
    required String syncId,
    required int expectedRev,
    required String blob,
  }) async => throw const RegSyncUnavailableException(message);

  @override
  Future<void> remove(String syncId) async =>
      throw const RegSyncUnavailableException(message);
}
