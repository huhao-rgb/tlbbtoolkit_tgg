import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';
import 'package:tlbbtoolkit/features/music/data/music_file_picker.dart';
import 'package:tlbbtoolkit/features/music/data/repositories/music_player_repository_impl.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';
import 'package:tlbbtoolkit/features/music/presentation/providers/music_player_providers.dart';

import 'music_fakes.dart';

void main() {
  const trackA = MusicTrack(path: '/music/a.mp3', name: '大理城');
  const trackB = MusicTrack(path: '/music/b.mp3', name: '苏州');
  const trackC = MusicTrack(path: '/music/c.mp3', name: '洛阳');

  late FakeMusicEngine engine;
  late FakeMusicPlayerRepository repository;
  late FakeMusicFilePicker picker;
  late ProviderContainer container;
  late MusicPlayerController controller;

  void setUpContainer({MusicPlayerState? initial}) {
    engine = FakeMusicEngine();
    repository = FakeMusicPlayerRepository(
      initial ?? const MusicPlayerState(tracks: [trackA, trackB, trackC]),
    );
    picker = FakeMusicFilePicker();
    container = ProviderContainer.test(
      overrides: [
        musicPlayerRepositoryProvider.overrideWithValue(repository),
        musicEngineProvider.overrideWithValue(engine),
        musicFilePickerProvider.overrideWithValue(picker),
      ],
    );
    controller = container.read(musicPlayerControllerProvider.notifier);
  }

  group('播放控制', () {
    test('初始状态取自仓储：未选中、未播放', () {
      setUpContainer();
      expect(controller.state.tracks.length, 3);
      expect(controller.state.playing, isFalse);
      expect(controller.state.currentTrack, isNull);
    });

    test('只读取状态不会创建播放引擎（惰性，测试环境不触碰平台通道）', () {
      repository = FakeMusicPlayerRepository(
        const MusicPlayerState(tracks: [trackA]),
      );
      container = ProviderContainer.test(
        overrides: [
          musicPlayerRepositoryProvider.overrideWithValue(repository),
          musicEngineProvider.overrideWith(
            (ref) => throw StateError('不应创建播放引擎'),
          ),
        ],
      );
      final lazyController = container.read(
        musicPlayerControllerProvider.notifier,
      );
      expect(lazyController.state.tracks.length, 1);

      // 直到真正播放前都不应触碰引擎：只要读到就会命中上面抛出的守卫。
      Object? error;
      try {
        container.read(musicEngineProvider);
      } on Object catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error.toString(), contains('不应创建播放引擎'));
    });

    test('空列表时播放 / 切歌均为空操作', () async {
      setUpContainer(initial: const MusicPlayerState());
      await controller.toggle();
      await controller.next();
      await controller.previous();
      expect(engine.playedPaths, isEmpty);
      expect(controller.state.currentIndex, -1);
    });

    test('playAt：按当前音量与循环模式起播，并选中该曲目', () async {
      setUpContainer(
        initial: const MusicPlayerState(
          tracks: [trackA, trackB],
          volume: .4,
          loop: true,
        ),
      );
      await controller.playAt(1);

      expect(engine.playedPaths, ['/music/b.mp3']);
      expect(engine.volume, .4);
      expect(engine.loop, isTrue);
      expect(controller.state.currentIndex, 1);
      expect(controller.state.playing, isTrue);
      expect(controller.state.unavailable, isEmpty);
    });

    test('playAt 下标越界时忽略', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA]));
      await controller.playAt(3);
      expect(engine.playedPaths, isEmpty);
      expect(controller.state.currentIndex, -1);
    });

    test('播放失败（文件缺失 / 沙盒失效）标记为不可用并停表', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      engine.failOnPlay = true;
      await controller.playAt(0);

      expect(controller.state.playing, isFalse);
      expect(controller.state.unavailable, contains('/music/a.mp3'));
      expect(controller.state.currentIndex, 0);
    });

    test('next / previous 在列表内环绕', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      await controller.playAt(1);
      await controller.next();
      expect(controller.state.currentIndex, 0);
      await controller.previous();
      expect(controller.state.currentIndex, 1);
    });

    test('从未选中时 next / previous 均指向第一首', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      await controller.previous();
      expect(controller.state.currentIndex, 0);
    });

    test('未选中任何曲目时 toggle 从第一首开始播放', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      await controller.toggle();
      expect(engine.playedPaths, ['/music/a.mp3']);
      expect(controller.state.currentIndex, 0);
      expect(controller.state.playing, isTrue);
    });

    test('toggle：播放中暂停；再次 toggle 续播（不重新起播）', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA]));
      await controller.playAt(0);
      await controller.toggle(); // 暂停
      expect(controller.state.playing, isFalse);
      expect(engine.calls, contains('pause'));

      await controller.toggle(); // 续播
      expect(controller.state.playing, isTrue);
      expect(engine.calls, contains('resume'));
      // 只起播过一次，续播走 resume。
      expect(engine.playedPaths, ['/music/a.mp3']);
    });

    test('暂停后切换曲目再回来：重新起播而非 resume', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      await controller.playAt(0);
      await controller.toggle(); // 暂停
      await controller.playAt(1);
      expect(engine.playedPaths, ['/music/a.mp3', '/music/b.mp3']);
    });

    test('循环关闭时播放结束自动下一首；开启时保持当前曲目', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      await controller.playAt(0);
      engine.emitCompleted();
      await pumpEventQueue();
      expect(controller.state.currentIndex, 1);

      await controller.toggleLoop();
      expect(controller.state.loop, isTrue);
      engine.emitCompleted();
      await pumpEventQueue();
      // 循环模式交给引擎单曲循环，控制器不再切歌。
      expect(controller.state.currentIndex, 1);
    });
  });

  group('偏好与列表', () {
    test('setVolume：更新状态并下发引擎（含边界收敛）', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA]));
      await controller.playAt(0); // 创建引擎
      await controller.setVolume(2);
      expect(controller.state.volume, 1);
      expect(engine.volume, 1);

      await controller.setVolume(-1);
      expect(controller.state.volume, 0);
      expect(engine.volume, 0);
    });

    test('toggleLoop：更新状态并下发引擎', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA]));
      await controller.playAt(0);
      await controller.toggleLoop();
      expect(controller.state.loop, isTrue);
      expect(engine.loop, isTrue);
    });

    test('addLocalFiles：追加曲目并忽略已在列表中的路径', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA]));
      picker.result = const [trackA, trackB, trackB];
      final result = await controller.addLocalFiles();

      expect(result.picked, 3);
      expect(result.added, 1);
      expect(controller.state.tracks.map((t) => t.name), ['大理城', '苏州']);
    });

    test('addLocalFiles：用户取消时不做变更', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA]));
      picker.result = const <MusicTrack>[];
      final result = await controller.addLocalFiles();
      expect(result.added, 0);
      expect(controller.state.tracks.length, 1);
    });

    test('状态变更会落盘（列表 / 音量 / 循环 / 当前曲目）', () async {
      setUpContainer(initial: const MusicPlayerState(tracks: [trackA, trackB]));
      await controller.playAt(1);
      await controller.setVolume(.2);
      await controller.toggleLoop();
      await pumpEventQueue();

      expect(repository.saveCount, greaterThanOrEqualTo(3));
      expect(repository.state.currentIndex, 1);
      expect(repository.state.volume, .2);
      expect(repository.state.loop, isTrue);
    });
  });
}
