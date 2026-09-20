// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MusicTrack {

/// 本地文件绝对路径，同时作为曲目唯一标识（用于判重 / 定位失效项）。
 String get path;/// 展示名：文件名去掉扩展名。
 String get name;
/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicTrackCopyWith<MusicTrack> get copyWith => _$MusicTrackCopyWithImpl<MusicTrack>(this as MusicTrack, _$identity);

  /// Serializes this MusicTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicTrack&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicTrack;
  return Object.hash(runtimeType,_this.path,_this.name);
}

@override
String toString() {
  final _this = this as MusicTrack;
  return 'MusicTrack(path: ${_this.path}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $MusicTrackCopyWith<$Res>  {
  factory $MusicTrackCopyWith(MusicTrack value, $Res Function(MusicTrack) _then) = _$MusicTrackCopyWithImpl;
@useResult
$Res call({
 String path, String name
});




}
/// @nodoc
class _$MusicTrackCopyWithImpl<$Res>
    implements $MusicTrackCopyWith<$Res> {
  _$MusicTrackCopyWithImpl(this._self, this._then);

  final MusicTrack _self;
  final $Res Function(MusicTrack) _then;

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,}) {
  return _then(MusicTrack(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicTrack].
extension MusicTrackPatterns on MusicTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicTrack value)  $default,){
final _that = this;
switch (_that) {
case _MusicTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicTrack value)?  $default,){
final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
return $default(_that.path,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name)  $default,) {final _that = this;
switch (_that) {
case _MusicTrack():
return $default(_that.path,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name)?  $default,) {final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
return $default(_that.path,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicTrack implements MusicTrack {
  const _MusicTrack({required this.path, required this.name});
  factory _MusicTrack.fromJson(Map<String, dynamic> json) => _$MusicTrackFromJson(json);

/// 本地文件绝对路径，同时作为曲目唯一标识（用于判重 / 定位失效项）。
@override final  String path;
/// 展示名：文件名去掉扩展名。
@override final  String name;

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicTrackCopyWith<_MusicTrack> get copyWith => __$MusicTrackCopyWithImpl<_MusicTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicTrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicTrack&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path,name);
}

@override
String toString() {
    return 'MusicTrack(path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MusicTrackCopyWith<$Res> implements $MusicTrackCopyWith<$Res> {
  factory _$MusicTrackCopyWith(_MusicTrack value, $Res Function(_MusicTrack) _then) = __$MusicTrackCopyWithImpl;
@override @useResult
$Res call({
 String path, String name
});




}
/// @nodoc
class __$MusicTrackCopyWithImpl<$Res>
    implements _$MusicTrackCopyWith<$Res> {
  __$MusicTrackCopyWithImpl(this._self, this._then);

  final _MusicTrack _self;
  final $Res Function(_MusicTrack) _then;

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,}) {
  return _then(_MusicTrack(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
