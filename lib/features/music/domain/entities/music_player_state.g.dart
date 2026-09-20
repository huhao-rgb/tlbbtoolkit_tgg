// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_player_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MusicPlayerState _$MusicPlayerStateFromJson(Map<String, dynamic> json) =>
    _MusicPlayerState(
      tracks:
          (json['tracks'] as List<dynamic>?)
              ?.map((e) => MusicTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MusicTrack>[],
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? -1,
      playing: json['playing'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? .7,
      loop: json['loop'] as bool? ?? false,
      unavailable:
          (json['unavailable'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
    );

Map<String, dynamic> _$MusicPlayerStateToJson(_MusicPlayerState instance) =>
    <String, dynamic>{
      'tracks': instance.tracks,
      'currentIndex': instance.currentIndex,
      'playing': instance.playing,
      'volume': instance.volume,
      'loop': instance.loop,
      'unavailable': instance.unavailable.toList(),
    };
