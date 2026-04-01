// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TodoDto {

 String get uuid; String get title; String? get description; DateTime get createdAt; DateTime? get expiresAt; DateTime? get completedAt; ListScope get scope; String get customOrder; Set<String> get tagUuids;
/// Create a copy of TodoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoDtoCopyWith<TodoDto> get copyWith => _$TodoDtoCopyWithImpl<TodoDto>(this as TodoDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoDto&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.customOrder, customOrder) || other.customOrder == customOrder)&&const DeepCollectionEquality().equals(other.tagUuids, tagUuids));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,title,description,createdAt,expiresAt,completedAt,scope,customOrder,const DeepCollectionEquality().hash(tagUuids));

@override
String toString() {
  return 'TodoDto(uuid: $uuid, title: $title, description: $description, createdAt: $createdAt, expiresAt: $expiresAt, completedAt: $completedAt, scope: $scope, customOrder: $customOrder, tagUuids: $tagUuids)';
}


}

/// @nodoc
abstract mixin class $TodoDtoCopyWith<$Res>  {
  factory $TodoDtoCopyWith(TodoDto value, $Res Function(TodoDto) _then) = _$TodoDtoCopyWithImpl;
@useResult
$Res call({
 String uuid, String title, String? description, DateTime createdAt, DateTime? expiresAt, DateTime? completedAt, ListScope scope, String customOrder, Set<String> tagUuids
});




}
/// @nodoc
class _$TodoDtoCopyWithImpl<$Res>
    implements $TodoDtoCopyWith<$Res> {
  _$TodoDtoCopyWithImpl(this._self, this._then);

  final TodoDto _self;
  final $Res Function(TodoDto) _then;

/// Create a copy of TodoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? title = null,Object? description = freezed,Object? createdAt = null,Object? expiresAt = freezed,Object? completedAt = freezed,Object? scope = null,Object? customOrder = null,Object? tagUuids = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ListScope,customOrder: null == customOrder ? _self.customOrder : customOrder // ignore: cast_nullable_to_non_nullable
as String,tagUuids: null == tagUuids ? _self.tagUuids : tagUuids // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoDto].
extension TodoDtoPatterns on TodoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoDto value)  $default,){
final _that = this;
switch (_that) {
case _TodoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoDto value)?  $default,){
final _that = this;
switch (_that) {
case _TodoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uuid,  String title,  String? description,  DateTime createdAt,  DateTime? expiresAt,  DateTime? completedAt,  ListScope scope,  String customOrder,  Set<String> tagUuids)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoDto() when $default != null:
return $default(_that.uuid,_that.title,_that.description,_that.createdAt,_that.expiresAt,_that.completedAt,_that.scope,_that.customOrder,_that.tagUuids);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uuid,  String title,  String? description,  DateTime createdAt,  DateTime? expiresAt,  DateTime? completedAt,  ListScope scope,  String customOrder,  Set<String> tagUuids)  $default,) {final _that = this;
switch (_that) {
case _TodoDto():
return $default(_that.uuid,_that.title,_that.description,_that.createdAt,_that.expiresAt,_that.completedAt,_that.scope,_that.customOrder,_that.tagUuids);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uuid,  String title,  String? description,  DateTime createdAt,  DateTime? expiresAt,  DateTime? completedAt,  ListScope scope,  String customOrder,  Set<String> tagUuids)?  $default,) {final _that = this;
switch (_that) {
case _TodoDto() when $default != null:
return $default(_that.uuid,_that.title,_that.description,_that.createdAt,_that.expiresAt,_that.completedAt,_that.scope,_that.customOrder,_that.tagUuids);case _:
  return null;

}
}

}

/// @nodoc


class _TodoDto extends TodoDto {
  const _TodoDto({required this.uuid, required this.title, this.description, required this.createdAt, this.expiresAt, this.completedAt, required this.scope, required this.customOrder, final  Set<String> tagUuids = const {}}): _tagUuids = tagUuids,super._();
  

@override final  String uuid;
@override final  String title;
@override final  String? description;
@override final  DateTime createdAt;
@override final  DateTime? expiresAt;
@override final  DateTime? completedAt;
@override final  ListScope scope;
@override final  String customOrder;
 final  Set<String> _tagUuids;
@override@JsonKey() Set<String> get tagUuids {
  if (_tagUuids is EqualUnmodifiableSetView) return _tagUuids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tagUuids);
}


/// Create a copy of TodoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoDtoCopyWith<_TodoDto> get copyWith => __$TodoDtoCopyWithImpl<_TodoDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoDto&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.customOrder, customOrder) || other.customOrder == customOrder)&&const DeepCollectionEquality().equals(other._tagUuids, _tagUuids));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,title,description,createdAt,expiresAt,completedAt,scope,customOrder,const DeepCollectionEquality().hash(_tagUuids));

@override
String toString() {
  return 'TodoDto(uuid: $uuid, title: $title, description: $description, createdAt: $createdAt, expiresAt: $expiresAt, completedAt: $completedAt, scope: $scope, customOrder: $customOrder, tagUuids: $tagUuids)';
}


}

/// @nodoc
abstract mixin class _$TodoDtoCopyWith<$Res> implements $TodoDtoCopyWith<$Res> {
  factory _$TodoDtoCopyWith(_TodoDto value, $Res Function(_TodoDto) _then) = __$TodoDtoCopyWithImpl;
@override @useResult
$Res call({
 String uuid, String title, String? description, DateTime createdAt, DateTime? expiresAt, DateTime? completedAt, ListScope scope, String customOrder, Set<String> tagUuids
});




}
/// @nodoc
class __$TodoDtoCopyWithImpl<$Res>
    implements _$TodoDtoCopyWith<$Res> {
  __$TodoDtoCopyWithImpl(this._self, this._then);

  final _TodoDto _self;
  final $Res Function(_TodoDto) _then;

/// Create a copy of TodoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? title = null,Object? description = freezed,Object? createdAt = null,Object? expiresAt = freezed,Object? completedAt = freezed,Object? scope = null,Object? customOrder = null,Object? tagUuids = null,}) {
  return _then(_TodoDto(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ListScope,customOrder: null == customOrder ? _self.customOrder : customOrder // ignore: cast_nullable_to_non_nullable
as String,tagUuids: null == tagUuids ? _self._tagUuids : tagUuids // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
