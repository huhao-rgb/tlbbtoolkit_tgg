// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MusicPlayerState {

/// 播放列表（本地导入的音频文件，按导入顺序）。
 List<MusicTrack> get tracks;/// 当前曲目下标；`-1` 表示尚未选中任何曲目。
 int get currentIndex;/// 是否正在播放（供顶栏按钮切换图标 / 均衡器动画）。
 bool get playing;/// 音量 0..1（持久化为 0..100 的整数百分比）。
 double get volume;/// 循环模式：开启后单曲循环，关闭则播完自动下一首。
 bool get loop;/// 文件已不可用的曲目路径集合（被移动 / 删除，或沙盒授权失效）。
///
/// 桌面沙盒下「重启后重新访问用户选择的文件」可能被拒，
/// 表现为播放失败，此时把该曲目标记为不可用并在列表中提示。
 Set<String> get unavailable;
/// Create a copy of MusicPlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicPlayerStateCopyWith<MusicPlayerState> get copyWith => _$MusicPlayerStateCopyWithImpl<MusicPlayerState>(this as MusicPlayerState, _$identity);

  /// Serializes this MusicPlayerState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicPlayerState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicPlayerState&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.playing, _this.playing) || other.playing == _this.playing)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.loop, _this.loop) || other.loop == _this.loop)&&const DeepCollectionEquality().equals(other.unavailable, _this.unavailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicPlayerState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.tracks),_this.currentIndex,_this.playing,_this.volume,_this.loop,const DeepCollectionEquality().hash(_this.unavailable));
}

@override
String toString() {
  final _this = this as MusicPlayerState;
  return 'MusicPlayerState(tracks: ${_this.tracks}, currentIndex: ${_this.currentIndex}, playing: ${_this.playing}, volume: ${_this.volume}, loop: ${_this.loop}, unavailable: ${_this.unavailable})';
}


}

/// @nodoc
abstract mixin class $MusicPlayerStateCopyWith<$Res>  {
  factory $MusicPlayerStateCopyWith(MusicPlayerState value, $Res Function(MusicPlayerState) _then) = _$MusicPlayerStateCopyWithImpl;
@useResult
$Res call({
 List<MusicTrack> tracks, int currentIndex, bool playing, double volume, bool loop, Set<String> unavailable
});




}
/// @nodoc
class _$MusicPlayerStateCopyWithImpl<$Res>
    implements $MusicPlayerStateCopyWith<$Res> {
  _$MusicPlayerStateCopyWithImpl(this._self, this._then);

  final MusicPlayerState _self;
  final $Res Function(MusicPlayerState) _then;

/// Create a copy of MusicPlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,Object? currentIndex = null,Object? playing = null,Object? volume = null,Object? loop = null,Object? unavailable = null,}) {
  return _then(MusicPlayerState(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<MusicTrack>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicPlayerState].
extension MusicPlayerStatePatterns on MusicPlayerState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicPlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicPlayerState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicPlayerState value)  $default,){
final _that = this;
switch (_that) {
case _MusicPlayerState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicPlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _MusicPlayerState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MusicTrack> tracks,  int currentIndex,  bool playing,  double volume,  bool loop,  Set<String> unavailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicPlayerState() when $default != null:
return $default(_that.tracks,_that.currentIndex,_that.playing,_that.volume,_that.loop,_that.unavailable);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MusicTrack> tracks,  int currentIndex,  bool playing,  double volume,  bool loop,  Set<String> unavailable)  $default,) {final _that = this;
switch (_that) {
case _MusicPlayerState():
return $default(_that.tracks,_that.currentIndex,_that.playing,_that.volume,_that.loop,_that.unavailable);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MusicTrack> tracks,  int currentIndex,  bool playing,  double volume,  bool loop,  Set<String> unavailable)?  $default,) {final _that = this;
switch (_that) {
case _MusicPlayerState() when $default != null:
return $default(_that.tracks,_that.currentIndex,_that.playing,_that.volume,_that.loop,_that.unavailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicPlayerState extends MusicPlayerState {
  const _MusicPlayerState({ List<MusicTrack> tracks = const <MusicTrack>[], this.currentIndex = -1, this.playing = false, this.volume = .7, this.loop = false,  Set<String> unavailable = const <String>{}}): _tracks = tracks,_unavailable = unavailable,super._();
  factory _MusicPlayerState.fromJson(Map<String, dynamic> json) => _$MusicPlayerStateFromJson(json);

/// 播放列表（本地导入的音频文件，按导入顺序）。
 final  List<MusicTrack> _tracks;
/// 播放列表（本地导入的音频文件，按导入顺序）。
@override@JsonKey() List<MusicTrack> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

/// 当前曲目下标；`-1` 表示尚未选中任何曲目。
@override@JsonKey() final  int currentIndex;
/// 是否正在播放（供顶栏按钮切换图标 / 均衡器动画）。
@override@JsonKey() final  bool playing;
/// 音量 0..1（持久化为 0..100 的整数百分比）。
@override@JsonKey() final  double volume;
/// 循环模式：开启后单曲循环，关闭则播完自动下一首。
@override@JsonKey() final  bool loop;
/// 文件已不可用的曲目路径集合（被移动 / 删除，或沙盒授权失效）。
///
/// 桌面沙盒下「重启后重新访问用户选择的文件」可能被拒，
/// 表现为播放失败，此时把该曲目标记为不可用并在列表中提示。
 final  Set<String> _unavailable;
/// 文件已不可用的曲目路径集合（被移动 / 删除，或沙盒授权失效）。
///
/// 桌面沙盒下「重启后重新访问用户选择的文件」可能被拒，
/// 表现为播放失败，此时把该曲目标记为不可用并在列表中提示。
@override@JsonKey() Set<String> get unavailable {
  if (_unavailable is EqualUnmodifiableSetView) return _unavailable;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_unavailable);
}


/// Create a copy of MusicPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicPlayerStateCopyWith<_MusicPlayerState> get copyWith => __$MusicPlayerStateCopyWithImpl<_MusicPlayerState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicPlayerStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicPlayerState&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.loop, loop) || other.loop == loop)&&const DeepCollectionEquality().equals(other.unavailable, _unavailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks),currentIndex,playing,volume,loop,const DeepCollectionEquality().hash(_unavailable));
}

@override
String toString() {
    return 'MusicPlayerState(tracks: $tracks, currentIndex: $currentIndex, playing: $playing, volume: $volume, loop: $loop, unavailable: $unavailable)';
}


}

/// @nodoc
abstract mixin class _$MusicPlayerStateCopyWith<$Res> implements $MusicPlayerStateCopyWith<$Res> {
  factory _$MusicPlayerStateCopyWith(_MusicPlayerState value, $Res Function(_MusicPlayerState) _then) = __$MusicPlayerStateCopyWithImpl;
@override @useResult
$Res call({
 List<MusicTrack> tracks, int currentIndex, bool playing, double volume, bool loop, Set<String> unavailable
});




}
/// @nodoc
class __$MusicPlayerStateCopyWithImpl<$Res>
    implements _$MusicPlayerStateCopyWith<$Res> {
  __$MusicPlayerStateCopyWithImpl(this._self, this._then);

  final _MusicPlayerState _self;
  final $Res Function(_MusicPlayerState) _then;

/// Create a copy of MusicPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,Object? currentIndex = null,Object? playing = null,Object? volume = null,Object? loop = null,Object? unavailable = null,}) {
  return _then(_MusicPlayerState(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<MusicTrack>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,unavailable: null == unavailable ? _self._unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
