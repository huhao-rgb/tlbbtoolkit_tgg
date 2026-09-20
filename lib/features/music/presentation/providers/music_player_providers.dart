import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/audio/audioplayers_music_engine.dart';
import '../../data/music_file_picker.dart';
import '../../data/repositories/music_player_repository_impl.dart';
import '../../domain/entities/music_player_state.dart';
import '../../domain/music_engine.dart';

part 'music_player_providers.g.dart';

/// 怀旧音律播放器状态（对应原型 `bgmState` + `BGM_TRACKS` 相关逻辑）。
///
/// 与原型一致的行为约定：
/// - 播放列表只有本地导入的音乐（原型的内置五声音阶曲目未接入）；
/// - 上一首 / 下一首在列表内**环绕**（`bgmStep2`）；
/// - 循环模式开启 = 单曲循环，关闭 = 播完自动下一首（原型 `bgmAudio.onended`）；
/// - 音量 / 循环 / 上次曲目持久化（原型写 localStorage）。
///
/// [keepAlive]：播放器是全局单例，页面切换不应打断播放，
/// 也让「播完自动下一首」的订阅在顶栏重建时依然有效。
@Riverpod(keepAlive: true)
class MusicPlayerController extends _$MusicPlayerController {
  MusicEngine? _engine;
  StreamSubscription<void>? _completionSub;

  /// 引擎当前已加载的音源路径；用于区分「暂停后续播」与「重新起播」。
  String? _loadedPath;

  @override
  MusicPlayerState build() {
    // 只读仓储（同步），不触碰引擎：仅渲染顶栏按钮时不应创建插件实例。
    return ref.read(musicPlayerRepositoryProvider).load();
  }

  /// 惰性取得引擎；首次使用时挂上「播完 → 下一首」的订阅。
  MusicEngine get _ensureEngine {
    final existing = _engine;
    if (existing != null) return existing;
    final engine = ref.read(musicEngineProvider);
    _engine = engine;
    _completionSub = engine.onCompleted.listen((_) => _handleCompleted());
    ref.onDispose(() {
      _completionSub?.cancel();
      _completionSub = null;
    });
    return engine;
  }

  /// 播放列表中第 [index] 首；下标非法时什么都不做。
  Future<void> playAt(int index) async {
    if (index < 0 || index >= state.tracks.length) return;
    final track = state.tracks[index];
    // 先乐观更新 UI（按钮态 / 列表高亮立即响应），再落地实际播放。
    state = state.copyWith(
      currentIndex: index,
      playing: true,
      unavailable: {...state.unavailable}..remove(track.path),
    );
    _persist();
    try {
      await _ensureEngine.play(
        track.path,
        volume: state.volume,
        loop: state.loop,
      );
      _loadedPath = track.path;
    } on Object {
      // 文件被移动/删除，或桌面沙盒下重启后授权失效：标记为不可用并停表。
      _loadedPath = null;
      state = state.copyWith(
        playing: false,
        unavailable: {...state.unavailable, track.path},
      );
    }
  }

  /// 播放 / 暂停切换（对应原型 `bgmToggle`）。
  Future<void> toggle() async {
    if (state.tracks.isEmpty) return;
    final track = state.currentTrack;
    // 未选中任何曲目 → 从第一首开始。
    if (track == null) return playAt(0);

    if (state.playing) {
      state = state.copyWith(playing: false);
      _persist();
      await _ensureEngine.pause();
      return;
    }
    // 已加载过同一音源（暂停状态）→ 续播，避免重新解码与丢进度。
    if (_loadedPath == track.path) {
      state = state.copyWith(playing: true);
      _persist();
      await _ensureEngine.resume();
      return;
    }
    await playAt(state.currentIndex);
  }

  /// 下一首（环绕）。
  Future<void> next() => _step(1);

  /// 上一首（环绕）。
  Future<void> previous() => _step(-1);

  Future<void> _step(int delta) {
    final count = state.tracks.length;
    if (count == 0) return Future<void>.value();
    final from = state.currentIndex < 0 ? 0 : state.currentIndex + delta;
    return playAt((from % count + count) % count);
  }

  /// 音量 0..1（对应原型 `#bgmVol` 的 input 事件）。
  Future<void> setVolume(double volume) async {
    final value = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: value);
    _persist();
    // 引擎尚未创建时无需下发：起播时会带上最新音量。
    final engine = _engine;
    if (engine != null) await engine.setVolume(value);
  }

  /// 切换循环模式（对应原型 `#bgmLoop`）。
  Future<void> toggleLoop() async {
    state = state.copyWith(loop: !state.loop);
    _persist();
    final engine = _engine;
    if (engine != null) await engine.setLoop(state.loop);
  }

  /// 弹出文件选择器追加本地音乐。
  ///
  /// 返回「用户选中数量」与「实际新增数量」：重复路径会被忽略
  /// （同原型按 `URL` 追加前的去重意图），供 UI 提示"已在列表中"。
  Future<({int picked, int added})> addLocalFiles() async {
    final picked = await ref.read(musicFilePickerProvider).pick();
    if (picked.isEmpty) return (picked: 0, added: 0);
    final known = state.tracks.map((t) => t.path).toSet();
    final added = picked
        .where((t) => known.add(t.path))
        .toList(growable: false);
    if (added.isEmpty) return (picked: picked.length, added: 0);
    state = state.copyWith(tracks: [...state.tracks, ...added]);
    _persist();
    return (picked: picked.length, added: added.length);
  }

  /// 曲目自然播放结束：非循环模式下自动下一首（循环由引擎内部完成）。
  void _handleCompleted() {
    if (state.loop || state.tracks.isEmpty) return;
    unawaited(next());
  }

  void _persist() =>
      unawaited(ref.read(musicPlayerRepositoryProvider).save(state));
}
