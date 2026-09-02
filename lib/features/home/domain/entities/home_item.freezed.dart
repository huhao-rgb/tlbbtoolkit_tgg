// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeItem {

 int get id; String get title; String get subtitle; bool get isFavorite;
/// Create a copy of HomeItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeItemCopyWith<HomeItem> get copyWith => _$HomeItemCopyWithImpl<HomeItem>(this as HomeItem, _$identity);

  /// Serializes this HomeItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.isFavorite, _this.isFavorite) || other.isFavorite == _this.isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeItem;
  return Object.hash(runtimeType,_this.id,_this.title,_this.subtitle,_this.isFavorite);
}

@override
String toString() {
  final _this = this as HomeItem;
  return 'HomeItem(id: ${_this.id}, title: ${_this.title}, subtitle: ${_this.subtitle}, isFavorite: ${_this.isFavorite})';
}


}

/// @nodoc
abstract mixin class $HomeItemCopyWith<$Res>  {
  factory $HomeItemCopyWith(HomeItem value, $Res Function(HomeItem) _then) = _$HomeItemCopyWithImpl;
@useResult
$Res call({
 int id, String title, String subtitle, bool isFavorite
});




}
/// @nodoc
class _$HomeItemCopyWithImpl<$Res>
    implements $HomeItemCopyWith<$Res> {
  _$HomeItemCopyWithImpl(this._self, this._then);

  final HomeItem _self;
  final $Res Function(HomeItem) _then;

/// Create a copy of HomeItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? subtitle = null,Object? isFavorite = null,}) {
  return _then(HomeItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeItem].
extension HomeItemPatterns on HomeItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeItem value)  $default,){
final _that = this;
switch (_that) {
case _HomeItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeItem value)?  $default,){
final _that = this;
switch (_that) {
case _HomeItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String subtitle,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeItem() when $default != null:
return $default(_that.id,_that.title,_that.subtitle,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String subtitle,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _HomeItem():
return $default(_that.id,_that.title,_that.subtitle,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String subtitle,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _HomeItem() when $default != null:
return $default(_that.id,_that.title,_that.subtitle,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeItem implements HomeItem {
  const _HomeItem({required this.id, required this.title, this.subtitle = '', this.isFavorite = false});
  factory _HomeItem.fromJson(Map<String, dynamic> json) => _$HomeItemFromJson(json);

@override final  int id;
@override final  String title;
@override@JsonKey() final  String subtitle;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of HomeItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeItemCopyWith<_HomeItem> get copyWith => __$HomeItemCopyWithImpl<_HomeItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,subtitle,isFavorite);
}

@override
String toString() {
    return 'HomeItem(id: $id, title: $title, subtitle: $subtitle, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$HomeItemCopyWith<$Res> implements $HomeItemCopyWith<$Res> {
  factory _$HomeItemCopyWith(_HomeItem value, $Res Function(_HomeItem) _then) = __$HomeItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String subtitle, bool isFavorite
});




}
/// @nodoc
class __$HomeItemCopyWithImpl<$Res>
    implements _$HomeItemCopyWith<$Res> {
  __$HomeItemCopyWithImpl(this._self, this._then);

  final _HomeItem _self;
  final $Res Function(_HomeItem) _then;

/// Create a copy of HomeItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? subtitle = null,Object? isFavorite = null,}) {
  return _then(_HomeItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
