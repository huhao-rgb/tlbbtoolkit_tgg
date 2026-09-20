import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/music/data/repositories/music_player_repository_impl.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';

void main() {
  late LocalStorage storage;
  late MusicPlayerRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    repository = MusicPlayerRepositoryImpl(storage);
  });

  test('首次运行为空列表 + 默认偏好', () {
    final state = repository.load();
    expect(state.tracks, isEmpty);
    expect(state.currentIndex, -1);
    expect(state.volume, .7);
    expect(state.loop, isFalse);
    expect(state.playing, isFalse);
  });

  test('保存后可读回列表与偏好；播放中状态不落盘', () async {
    await repository.save(
      const MusicPlayerState(
        tracks: [MusicTrack(path: '/music/a.mp3', name: '大理城')],
        currentIndex: 0,
        playing: true,
        volume: .35,
        loop: true,
      ),
    );

    final state = repository.load();
    expect(state.tracks.single.path, '/music/a.mp3');
    expect(state.tracks.single.name, '大理城');
    expect(state.currentIndex, 0);
    expect(state.volume, .35);
    expect(state.loop, isTrue);
    // playing 属运行时状态，重新读取时归位。
    expect(state.playing, isFalse);
  });

  test('下标越界时回退为"未选中"，避免取当前曲目越界', () async {
    await repository.save(
      const MusicPlayerState(
        tracks: [MusicTrack(path: '/music/a.mp3', name: '大理城')],
        currentIndex: 5,
      ),
    );
    expect(repository.load().currentIndex, -1);
  });

  test('落盘数据损坏时回退默认状态', () async {
    await storage.setJson('music_player', {'tracks': 'not-a-list'});
    final state = repository.load();
    expect(state.tracks, isEmpty);
    expect(state.currentIndex, -1);
  });
}
