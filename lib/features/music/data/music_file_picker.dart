import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';

part 'music_file_picker.g.dart';

/// 本地音乐选择器（对应原型弹层右下角的「本地」按钮 →
/// `<input type="file" accept="audio/*" multiple hidden>`）。
///
/// 复用项目已有的 file_selector：各端均走系统文件选择器，拿到的是文件路径。
/// 与原型用 `URL.createObjectURL` 生成临时引用不同，这里直接持久化路径，
/// 因此下次启动仍能按路径播放（沙盒下可能授权失效，见
/// `MusicPlayerState.unavailable`）。
class MusicFilePicker {
  const MusicFilePicker();

  /// 支持的音频扩展名（`accept="audio/*"` 的可枚举化写法）。
  ///
  /// 只给 `extensions`：Apple 端会转成 UTType，Android 端会转成 MIME，
  /// 各平台都能正确过滤，避免 MIME 通配符在部分平台不被接受。
  static const XTypeGroup _audioType = XTypeGroup(
    label: '音频',
    extensions: [
      'mp3',
      'm4a',
      'm4b',
      'aac',
      'wav',
      'wave',
      'flac',
      'ogg',
      'oga',
      'opus',
      'wma',
      'aiff',
      'aif',
      'ape',
      'mp4',
    ],
  );

  /// 弹出系统文件选择器，返回所选音频（用户取消时返回空列表）。
  Future<List<MusicTrack>> pick() async {
    final files = await openFiles(acceptedTypeGroups: const [_audioType]);
    return files
        .map((f) => MusicTrack(path: f.path, name: trackNameFromPath(f.path)))
        .toList(growable: false);
  }
}

/// 由文件路径推导曲目展示名（取文件名并去掉扩展名）。
String trackNameFromPath(String path) {
  final base = path.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  final name = dot > 0 ? base.substring(0, dot) : base;
  return name.trim().isEmpty ? base : name;
}

/// 本地音乐选择器的依赖注入。
@riverpod
MusicFilePicker musicFilePicker(Ref ref) => const MusicFilePicker();
