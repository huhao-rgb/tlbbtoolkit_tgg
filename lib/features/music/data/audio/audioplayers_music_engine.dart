import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/features/music/domain/music_engine.dart';

part 'audioplayers_music_engine.g.dart';

/// 基于 audioplayers 的播放引擎实现。
///
/// 全程只用一个 [AudioPlayer]（原型同样只有一个 `bgmAudio`），
/// 换曲 = 重新 `play` 新音源；循环模式映射为 [ReleaseMode.loop]。
class AudioPlayersMusicEngine implements MusicEngine {
  AudioPlayersMusicEngine() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get onCompleted => _player.onPlayerComplete;

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
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setLoop(bool loop) =>
      _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);

  @override
  void dispose() {
    // dispose 是异步的，但引擎生命周期与 app 一致，无需等待。
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
