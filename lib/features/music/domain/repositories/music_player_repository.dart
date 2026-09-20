import '../entities/music_player_state.dart';

/// 播放器持久化仓储抽象。
///
/// 只负责「列表 + 偏好」的落盘/读取，不关心播放行为（见 [MusicEngine]）。
abstract interface class MusicPlayerRepository {
  /// 读取已持久化的播放器状态（首次运行为默认空状态）。
  ///
  /// 返回值的 [MusicPlayerState.playing] 恒为 `false`。
  MusicPlayerState load();

  /// 持久化列表与偏好（音量 / 循环 / 上次曲目）。
  Future<void> save(MusicPlayerState state);
}
