import 'dart:async';

import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';
import 'package:tlbbtoolkit/features/music/domain/music_engine.dart';
import 'package:tlbbtoolkit/features/music/domain/repositories/music_player_repository.dart';

/// 假播放引擎：记录调用与参数，可模拟播放失败，可手工触发「播放结束」。
class FakeMusicEngine implements MusicEngine {
  final List<String> calls = <String>[];
  final List<String> playedPaths = <String>[];

  final StreamController<void> _completions =
      StreamController<void>.broadcast();

  /// 置 true 时 [play] 抛错（模拟文件被移动/删除，或桌面沙盒授权失效）。
  bool failOnPlay = false;

  double volume = .7;
  bool loop = false;

  /// 模拟当前曲目自然播放结束。
  void emitCompleted() => _completions.add(null);

  @override
  Stream<void> get onCompleted => _completions.stream;

  @override
  Future<void> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    if (failOnPlay) throw StateError('音频文件不可读');
    calls.add('play');
    playedPaths.add(path);
    this.volume = volume;
    this.loop = loop;
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> setVolume(double volume) async {
    calls.add('setVolume');
    this.volume = volume;
  }

  @override
  Future<void> setLoop(bool loop) async {
    calls.add('setLoop');
    this.loop = loop;
  }

  @override
  void dispose() => _completions.close();
}

/// 假仓储：内存持有状态，并记录落盘次数。
class FakeMusicPlayerRepository implements MusicPlayerRepository {
  FakeMusicPlayerRepository([this.state = const MusicPlayerState()]);

  MusicPlayerState state;
  int saveCount = 0;

  @override
  MusicPlayerState load() => state;

  @override
  Future<void> save(MusicPlayerState next) async {
    state = next;
    saveCount++;
  }
}

/// 假文件选择器：返回预置结果，模拟用户选择/取消。
class FakeMusicFilePicker extends MusicFilePicker {
  FakeMusicFilePicker([this.result = const <MusicTrack>[]]);

  List<MusicTrack> result;

  @override
  Future<List<MusicTrack>> pick() async => result;
}
