import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';
import 'package:tlbbtoolkit/features/music/data/repositories/music_player_repository_impl.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';
import 'package:tlbbtoolkit/features/music/presentation/providers/music_player_providers.dart';
import 'package:tlbbtoolkit/features/music/presentation/providers/music_progress_providers.dart';

import 'music_fakes.dart';

void main() {
  const trackA = MusicTrack(path: '/music/a.mp3', name: '大理城');
  const trackB = MusicTrack(path: '/music/b.mp3', name: '苏州');

  late FakeMusicEngine engine;
  late ProviderContainer container;

  /// 让广播流的事件送达（stream 事件在微任务里派发）。
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  void setUpContainer({int currentIndex = -1}) {
    engine = FakeMusicEngine();
    container = ProviderContainer.test(
      overrides: [
        musicPlayerRepositoryProvider.overrideWithValue(
          FakeMusicPlayerRepository(
            MusicPlayerState(
              tracks: const [trackA, trackB],
              currentIndex: currentIndex,
            ),
          ),
        ),
        musicEngineProvider.overrideWithValue(engine),
      ],
    );
    // 进度 provider 是惰性创建的，且 keepAlive：先建好订阅，
    // 否则在创建之前 emit 的事件会被直接丢掉。
    container.listen(musicProgressControllerProvider, (_, _) {});
  }

  group('MusicProgressController', () {
    test('初始进度为零、时长未知', () {
      setUpContainer();
      final progress = container.read(musicProgressControllerProvider);
      expect(progress.position, Duration.zero);
      expect(progress.duration, isNull);
      expect(progress.fraction, 0);
    });

    test('引擎上报的时长与位置合成进度，fraction 为两者之比', () async {
      setUpContainer();

      engine.emitDuration(const Duration(seconds: 100));
      engine.emitPosition(const Duration(seconds: 25));
      await flush();

      final progress = container.read(musicProgressControllerProvider);
      expect(progress.duration, const Duration(seconds: 100));
      expect(progress.position, const Duration(seconds: 25));
      expect(progress.fraction, .25);
    });

    test('200ms 以内的位置抖动被节流（实现按帧上报）', () async {
      setUpContainer();
      engine.emitPosition(const Duration(seconds: 10));
      await flush();
      expect(
        container.read(musicProgressControllerProvider).position,
        const Duration(seconds: 10),
      );

      engine.emitPosition(const Duration(milliseconds: 10100));
      await flush();
      expect(
        container.read(musicProgressControllerProvider).position,
        const Duration(seconds: 10),
        reason: '100ms 的增量应被忽略',
      );

      engine.emitPosition(const Duration(milliseconds: 10300));
      await flush();
      expect(
        container.read(musicProgressControllerProvider).position,
        const Duration(milliseconds: 10300),
      );
    });

    test('换曲时进度归零（不等引擎事件）', () async {
      setUpContainer();
      engine.emitDuration(const Duration(seconds: 100));
      engine.emitPosition(const Duration(seconds: 40));
      await flush();

      final player = container.read(musicPlayerControllerProvider.notifier);
      await player.playAt(1);
      await flush();

      final progress = container.read(musicProgressControllerProvider);
      expect(progress.position, Duration.zero);
      expect(progress.duration, isNull);
    });

    test('seekToFraction 按比例换算并乐观更新进度', () async {
      setUpContainer();
      engine.emitDuration(const Duration(seconds: 100));
      await flush();

      await container
          .read(musicProgressControllerProvider.notifier)
          .seekToFraction(.5);

      expect(engine.seeks, [const Duration(seconds: 50)]);
      final progress = container.read(musicProgressControllerProvider);
      expect(progress.position, const Duration(seconds: 50));
      expect(progress.fraction, .5);
    });

    test('seekToFraction 把比例夹到 0..1', () async {
      setUpContainer();
      engine.emitDuration(const Duration(seconds: 100));
      await flush();

      final controller = container.read(
        musicProgressControllerProvider.notifier,
      );
      await controller.seekToFraction(1.8);
      await controller.seekToFraction(-.5);

      expect(engine.seeks, [const Duration(seconds: 100), Duration.zero]);
    });

    test('时长未知时 seekToFraction 为空操作', () async {
      setUpContainer();
      await container
          .read(musicProgressControllerProvider.notifier)
          .seekToFraction(.5);

      expect(engine.seeks, isEmpty);
      expect(
        container.read(musicProgressControllerProvider).position,
        Duration.zero,
      );
    });
  });
}
