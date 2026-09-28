import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_store.dart';
import 'package:tlbbtoolkit/features/music/data/repositories/music_player_repository_impl.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';
import 'package:tlbbtoolkit/features/music/domain/music_engine.dart';

part 'music_player_providers.g.dart';

/// 怀旧音律播放器状态（对应原型 `bgmState` + `BGM_TRACKS` 相关逻辑）。
///
/// 与原型一致的行为约定：
/// - 播放列表只有本地导入的音乐（原型的内置五声音阶曲目未接入）；
/// - 上一首 / 下一首在列表内**环绕**（`bgmStep2`）；
/// - 循环模式开启 = 单曲循环，关闭 = 播完自动下一首（原型 `bgmAudio.onended`）；
/// - 音量 / 循环 / 上次曲目持久化（原型写 localStorage）。
///
/// 原型没有删除入口，列表左滑删除是**本次新增**的交互（见 [removeAt]）。
///
/// [keepAlive]：播放器是全局单例，页面切换不应打断播放，
/// 也让「播完自动下一首」的订阅在顶栏重建时依然有效。
@Riverpod(keepAlive: true)
class MusicPlayerController extends _$MusicPlayerController {
  MusicEngine? _engine;
  StreamSubscription<void>? _completionSub;
  StreamSubscription<Object>? _errorSub;

  /// 引擎当前已加载的音源路径；用于区分「暂停后续播」与「重新起播」。
  String? _loadedPath;

  @override
  MusicPlayerState build() {
    // 只读仓储（同步），不触碰引擎：仅渲染顶栏按钮时不应创建插件实例。
    return ref.read(musicPlayerRepositoryProvider).load();
  }

  /// 惰性取得引擎；首次使用时挂上「播完 → 下一首」与「出错 → 标记不可用」的订阅。
  MusicEngine get _ensureEngine {
    final existing = _engine;
    if (existing != null) return existing;
    final engine = ref.read(musicEngineProvider);
    _engine = engine;
    // 出错回调也挂在两条订阅上：即便某个实现漏了「事件流不携带错误」的契约，
    // 也不会变成直达根 zone 的 Unhandled Exception。
    _completionSub = engine.onCompleted.listen(
      (_) => _handleCompleted(),
      onError: (Object _) => _handlePlaybackFailure(),
    );
    _errorSub = engine.onError.listen(
      (Object _) => _handlePlaybackFailure(),
      onError: (Object _) => _handlePlaybackFailure(),
    );
    ref.onDispose(() {
      _completionSub?.cancel();
      _completionSub = null;
      _errorSub?.cancel();
      _errorSub = null;
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
  /// 选中的文件会**先复制进应用私有目录**再入列表（见 [MusicFileStore]）：
  /// 沙盒对「用户选中文件」的授权只活在一次进程内，直接存原路径重启后就播不了。
  ///
  /// 返回「用户选中数量」与「实际新增数量」：重复路径会被忽略
  /// （同原型按 `URL` 追加前的去重意图），供 UI 提示"已在列表中"。
  Future<({int picked, int added})> addLocalFiles() async {
    final picked = await ref.read(musicFilePickerProvider).pick();
    if (picked.isEmpty) return (picked: 0, added: 0);
    final store = ref.read(musicFileStoreProvider);
    final imported = <MusicTrack>[];
    for (final track in picked) {
      imported.add(track.copyWith(path: await store.import(track.path)));
    }
    final known = state.tracks.map((t) => t.path).toSet();
    final added = imported
        .where((t) => known.add(t.path))
        .toList(growable: false);
    if (added.isEmpty) return (picked: picked.length, added: 0);
    state = state.copyWith(tracks: [...state.tracks, ...added]);
    _persist();
    return (picked: picked.length, added: added.length);
  }

  /// 从列表移除第 [index] 首（列表左滑删除），同时回收磁盘副本。
  ///
  /// - 删的是当前曲目 → 停表、回到「未选中」（不自动续播下一首）；
  /// - 删的是当前曲目之前的项 → 当前下标前移，避免指向别的歌；
  /// - 落盘副本交给 [MusicFileStore.remove]：只删应用目录内的文件，
  ///   外部原文件（复制失败的回退路径）绝不动。
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= state.tracks.length) return;
    final removed = state.tracks[index];
    final wasCurrent = index == state.currentIndex;
    final tracks = [...state.tracks]..removeAt(index);
    final currentIndex = wasCurrent
        ? -1
        : (index < state.currentIndex
              ? state.currentIndex - 1
              : state.currentIndex);

    state = state.copyWith(
      tracks: tracks,
      currentIndex: currentIndex,
      playing: wasCurrent ? false : state.playing,
      unavailable: {...state.unavailable}..remove(removed.path),
    );
    _persist();

    if (wasCurrent) {
      _loadedPath = null;
      // 只导入没播过时引擎还没建：不要为了删除凭空创建插件实例。
      final engine = _engine;
      if (engine != null) await engine.stop();
    }
    unawaited(ref.read(musicFileStoreProvider).remove(removed.path));
  }

  /// 曲目自然播放结束：非循环模式下自动下一首（循环由引擎内部完成）。
  void _handleCompleted() {
    if (state.loop || state.tracks.isEmpty) return;
    unawaited(next());
  }

  /// 引擎报错（音源加载/解码失败，或桌面沙盒下无权读取）。
  ///
  /// macOS 的 audioplayers 后端在 `setSource` 失败时**不会**让 `play()` 报错，
  /// [playAt] 的 try/catch 抳不到，只能靠 [MusicEngine.onError] 感知：
  /// 此时把当前曲目标记为不可用并停表，避免 UI 卡在"正在播放但没声音"。
  void _handlePlaybackFailure() {
    final track = state.currentTrack;
    // 只有"以为在播"的时候才算起播失败；暂停期间迟到的错误直接忽略。
    if (track == null || !state.playing) return;
    _loadedPath = null;
    state = state.copyWith(
      playing: false,
      unavailable: {...state.unavailable, track.path},
    );
    _persist();
  }

  void _persist() =>
      unawaited(ref.read(musicPlayerRepositoryProvider).save(state));
}
