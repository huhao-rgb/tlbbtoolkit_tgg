import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';

part 'music_player_state.freezed.dart';
part 'music_player_state.g.dart';

/// 播放器状态（UI 直接订阅的唯一状态源）。
///
/// 其中 [tracks] / [currentIndex] / [volume] / [loop] 会持久化，
/// [playing] 与 [unavailable] 是运行时状态，重启后丢弃。
@freezed
abstract class MusicPlayerState with _$MusicPlayerState {
  const factory MusicPlayerState({
    /// 播放列表（本地导入的音频文件，按导入顺序）。
    @Default(<MusicTrack>[]) List<MusicTrack> tracks,

    /// 当前曲目下标；`-1` 表示尚未选中任何曲目。
    @Default(-1) int currentIndex,

    /// 是否正在播放（供顶栏按钮切换图标 / 均衡器动画）。
    @Default(false) bool playing,

    /// 音量 0..1（持久化为 0..100 的整数百分比）。
    @Default(.7) double volume,

    /// 循环模式：开启后单曲循环，关闭则播完自动下一首。
    @Default(false) bool loop,

    /// 文件已不可用的曲目路径集合（被移动 / 删除，或沙盒授权失效）。
    ///
    /// 桌面沙盒下「重启后重新访问用户选择的文件」可能被拒，
    /// 表现为播放失败，此时把该曲目标记为不可用并在列表中提示。
    @Default(<String>{}) Set<String> unavailable,
  }) = _MusicPlayerState;

  const MusicPlayerState._();

  /// 当前选中的曲目；未选中或下标越界时为 null。
  MusicTrack? get currentTrack =>
      currentIndex >= 0 && currentIndex < tracks.length
      ? tracks[currentIndex]
      : null;

  /// 播放列表是否为空。
  bool get isEmpty => tracks.isEmpty;

  factory MusicPlayerState.fromJson(Map<String, dynamic> json) =>
      _$MusicPlayerStateFromJson(json);
}
