import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_track.freezed.dart';
part 'music_track.g.dart';

/// 播放列表中的一首曲目。
///
/// 当前仅支持「本地导入」的音频文件（原型内置的五声音阶即兴合成曲目
/// 未接入），因此曲目全部由一个本地绝对路径描述。
@freezed
abstract class MusicTrack with _$MusicTrack {
  const factory MusicTrack({
    /// 本地文件绝对路径，同时作为曲目唯一标识（用于判重 / 定位失效项）。
    required String path,

    /// 展示名：文件名去掉扩展名。
    required String name,
  }) = _MusicTrack;

  factory MusicTrack.fromJson(Map<String, dynamic> json) =>
      _$MusicTrackFromJson(json);
}
