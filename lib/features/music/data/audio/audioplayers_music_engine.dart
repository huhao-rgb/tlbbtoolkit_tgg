import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/features/music/domain/music_engine.dart';

part 'audioplayers_music_engine.g.dart';

/// 丢弃 [source] 上的错误，让返回的事件流保持"干净"。
///
/// audioplayers 的错误走的是**流的 error 通道**（而非 Future），且一个错误会
/// 同时送达所有由 `eventStream` 派生的流；任何订阅方漏写 `onError` 都会变成
/// 直达根 zone 的 `Unhandled Exception`。
/// 引擎在构造函数里把错误统一收口到 [MusicEngine.onError]，事件流本身不再携带错误。
///
/// 注意：这里只做"丢弃"，不转发——否则每个被订阅的事件流都会重复上报同一个错误。
Stream<T> ignoreStreamErrors<T>(Stream<T> source) =>
    source.handleError((Object _) {});

/// 基于 audioplayers 的播放引擎实现。
///
/// 全程只用一个 [AudioPlayer]（原型同样只有一个 `bgmAudio`），
/// 换曲 = 重新 `play` 新音源；循环模式映射为 [ReleaseMode.loop]。
class AudioPlayersMusicEngine implements MusicEngine {
  AudioPlayersMusicEngine() : _player = AudioPlayer() {
    // audioplayers 把平台错误投递到 eventStream 的 **error 通道**：
    // 它是广播流，错误会同时送达所有由它派生的流（onPlayerComplete /
    // onDurationChanged …），谁漏写 onError 就会变成直达根 zone 的
    // "Unhandled Exception"。这里一次性收口，对外只走 [onError]。
    _errorSub = _player.eventStream.listen((_) {}, onError: _errors.add);
  }

  final AudioPlayer _player;

  /// 平台错误统一收口（见构造函数注释）。
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  StreamSubscription<Object?>? _errorSub;

  @override
  Stream<Object> get onError => _errors.stream;

  @override
  Stream<void> get onCompleted => ignoreStreamErrors(_player.onPlayerComplete);

  @override
  Future<void> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.setVolume(volume);
    // Web 上 file_selector 返回的是 blob/object URL，需按 URL 播放；
    // 其余平台按本地文件路径播放。
    await _player.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Stream<Duration> get onPositionChanged =>
      ignoreStreamErrors(_player.onPositionChanged);

  @override
  Stream<Duration> get onDurationChanged =>
      ignoreStreamErrors(_player.onDurationChanged);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setLoop(bool loop) =>
      _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);

  @override
  void dispose() {
    // dispose 是异步的，但引擎生命周期与 app 一致，无需等待。
    // 先断掉事件流订阅再关错误流，避免关闭后仍有错误写入。
    final errorSub = _errorSub;
    if (errorSub != null) unawaited(errorSub.cancel());
    unawaited(_errors.close());
    _player.dispose();
  }
}

/// 播放引擎的依赖注入。
///
/// [keepAlive] + 惰性读取：引擎只在首次播放/暂停等操作时才被创建，
/// 避免仅构建顶栏按钮（如 widget 测试）就去触碰平台通道。
@Riverpod(keepAlive: true)
MusicEngine musicEngine(Ref ref) {
  final engine = AudioPlayersMusicEngine();
  ref.onDispose(engine.dispose);
  return engine;
}
