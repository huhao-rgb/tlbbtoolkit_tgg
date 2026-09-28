import 'dart:async';

import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_store.dart';
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
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durations =
      StreamController<Duration>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  /// [seek] 收到的目标位置（按调用顺序）。
  final List<Duration> seeks = <Duration>[];

  /// 置 true 时 [play] 抛错（模拟文件被移动/删除，或桌面沙盒授权失效）。
  bool failOnPlay = false;

  double volume = .7;
  bool loop = false;

  /// 模拟当前曲目自然播放结束。
  void emitCompleted() => _completions.add(null);

  /// 模拟引擎上报播放位置。
  void emitPosition(Duration position) => _positions.add(position);

  /// 模拟引擎上报音源总时长。
  void emitDuration(Duration duration) => _durations.add(duration);

  /// 模拟引擎上报播放错误（音源加载失败 / 无权读取）。
  void emitError(Object error) => _errors.add(error);

  @override
  Stream<void> get onCompleted => _completions.stream;

  @override
  Stream<Object> get onError => _errors.stream;

  @override
  Stream<Duration> get onPositionChanged => _positions.stream;

  @override
  Stream<Duration> get onDurationChanged => _durations.stream;

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
  Future<void> seek(Duration position) async {
    calls.add('seek');
    seeks.add(position);
  }

  @override
  void dispose() {
    _completions.close();
    _positions.close();
    _durations.close();
    _errors.close();
  }
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

/// 假落盘器：把外路径映射成「应用目录」下的同名路径，记录调用。
class FakeMusicFileStore implements MusicFileStore {
  final List<String> imported = <String>[];
  final List<String> removed = <String>[];

  /// 置 true 时模拟复制失败（回退原路径）。
  bool failImport = false;

  @override
  Future<String> import(String sourcePath) async {
    imported.add(sourcePath);
    if (failImport) return sourcePath;
    final name = sourcePath.split(RegExp(r'[/\\]')).last;
    return '/app/music/$name';
  }

  @override
  Future<bool> remove(String path) async {
    removed.add(path);
    // 真实的 MusicFileStore 只删应用目录内的副本，外部路径返回 false。
    return path.startsWith('/app/music/');
  }
}
