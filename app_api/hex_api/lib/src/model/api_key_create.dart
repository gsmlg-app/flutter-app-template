//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hex_api/src/model/api_key_permissions_inner.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_key_create.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiKeyCreate {
  /// Returns a new [ApiKeyCreate] instance.
  ApiKeyCreate({
    required this.name,
    this.permissions,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'permissions',
    required: false,
    includeIfNull: false,
  )
  final List<ApiKeyPermissionsInner>? permissions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKeyCreate &&
          other.name == name &&
          other.permissions == permissions;

  @override
  int get hashCode => name.hashCode + permissions.hashCode;

  factory ApiKeyCreate.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
