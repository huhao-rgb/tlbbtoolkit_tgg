import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';
import 'package:tlbbtoolkit/features/music/presentation/providers/music_player_providers.dart';

part 'music_progress_providers.g.dart';

/// 位置事件的最小间隔。
///
/// audioplayers 默认每帧上报播放位置；进度条只需要"看起来连续"的粒度，
/// 这里收敛到 200ms（原型 `setInterval(tick,500)` 是 500ms 轮询），
/// 避免每帧刷新状态与重建进度条。
const Duration kMusicPositionGranularity = Duration(milliseconds: 200);

/// 播放进度快照（进度条订阅的唯一状态）。
class MusicProgress {
  const MusicProgress({this.position = Duration.zero, this.duration});

  /// 当前播放位置。
  final Duration position;

  /// 当前音源总时长；未选曲或尚未加载完成时为 null（UI 显示 `--:--`）。
  final Duration? duration;

  /// 进度比例 0..1；时长未知或为零时返回 0。
  double get fraction {
    final total = duration;
    if (total == null || total <= Duration.zero) return 0;
    return (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is MusicProgress &&
      other.position == position &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(position, duration);
}

/// 当前曲目的播放进度（对应原型 `.bgm-prog` 的轮询 tick）。
///
/// 单独成 provider 而不是塞进 `MusicPlayerState`：
/// 位置每 200ms 变一次，混进播放器状态会让整个面板（含播放列表）跟着重建。
///
/// [keepAlive]：面板关掉再打开时进度接着走，不必重新等引擎上报时长。
@Riverpod(keepAlive: true)
class MusicProgressController extends _$MusicProgressController {
  @override
  MusicProgress build() {
    final engine = ref.watch(musicEngineProvider);
    final positionSub = engine.onPositionChanged.listen((position) {
      // 位置在 200ms 内的小幅抖动（含暂停时的重复上报）直接忽略。
      if ((position - state.position).abs() < kMusicPositionGranularity) return;
      state = MusicProgress(position: position, duration: state.duration);
    });
    final durationSub = engine.onDurationChanged.listen(
      (duration) =>
          state = MusicProgress(position: state.position, duration: duration),
    );
    // 换曲：新音源的时长/位置事件到达前先把进度归零，
    // 否则会短暂显示上一首的进度。
    ref.listen(musicPlayerControllerProvider, (previous, next) {
      if (previous?.currentIndex != next.currentIndex) {
        state = const MusicProgress();
      }
    });
    ref.onDispose(() {
      positionSub.cancel();
      durationSub.cancel();
    });
    return const MusicProgress();
  }

  /// 跳转到整首的 [fraction]（0..1）处（进度条拖动 / 点击）。
  ///
  /// 时长未知时忽略：此时无从换算目标位置（进度条本身也是禁用的）。
  Future<void> seekToFraction(double fraction) async {
    final total = state.duration;
    if (total == null || total <= Duration.zero) return;
    final target = total * fraction.clamp(0.0, 1.0);
    // 乐观更新：引擎的位置回包要下一次上报才到，先让滑块停在目标处。
    state = MusicProgress(position: target, duration: total);
    await ref.read(musicEngineProvider).seek(target);
  }
}
