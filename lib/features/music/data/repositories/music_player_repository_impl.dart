import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:tlbbtoolkit/core/di/providers.dart';
import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_player_state.dart';
import 'package:tlbbtoolkit/features/music/domain/entities/music_track.dart';
import 'package:tlbbtoolkit/features/music/domain/repositories/music_player_repository.dart';

part 'music_player_repository_impl.g.dart';

/// 播放器的本地实现：列表与偏好作为单个 JSON 存在 [LocalStorage] 中。
///
/// 持久化字段刻意与 [MusicPlayerState] 分离（不含 playing / unavailable），
/// 保证运行时状态不会污染落盘数据。
class MusicPlayerRepositoryImpl implements MusicPlayerRepository {
  MusicPlayerRepositoryImpl(this._storage);

  static const String _storageKey = 'music_player';

  final LocalStorage _storage;

  @override
  MusicPlayerState load() {
    final json = _storage.getJson(_storageKey);
    if (json == null) return const MusicPlayerState();
    try {
      final tracks = (json['tracks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MusicTrack.fromJson)
          .toList(growable: false);
      final volume = (json['volume'] as num?)?.toDouble() ?? .7;
      final index = (json['currentIndex'] as num?)?.toInt() ?? -1;
      return MusicPlayerState(
        tracks: tracks,
        // 越界/空列表统一回落到「未选中」，避免 UI 取当前曲目时越界。
        currentIndex: index >= 0 && index < tracks.length ? index : -1,
        volume: volume.clamp(0.0, 1.0),
        loop: json['loop'] as bool? ?? false,
      );
    } on Object {
      // 数据损坏时回退到默认状态，不让播放器拖垮整个顶栏。
      return const MusicPlayerState();
    }
  }

  @override
  Future<void> save(MusicPlayerState state) => _storage.setJson(_storageKey, {
    'tracks': state.tracks.map((t) => t.toJson()).toList(),
    'currentIndex': state.currentIndex,
    'volume': state.volume,
    'loop': state.loop,
  });
}

/// 播放器仓储的依赖注入。
@riverpod
MusicPlayerRepository musicPlayerRepository(Ref ref) =>
    MusicPlayerRepositoryImpl(ref.watch(localStorageProvider));
