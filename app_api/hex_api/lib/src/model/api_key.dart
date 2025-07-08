//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hex_api/src/model/api_key_permissions_inner.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_key.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiKey {
  /// Returns a new [ApiKey] instance.
  ApiKey({
    required this.name,
    required this.permissions,
    this.revokedAt,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'permissions',
    required: true,
    includeIfNull: false,
  )
  final List<ApiKeyPermissionsInner> permissions;

  @JsonKey(
    name: r'revoked_at',
    required: false,
    includeIfNull: false,
  )
  final DateTime? revokedAt;

  @JsonKey(
    name: r'inserted_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime insertedAt;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @JsonKey(
    name: r'url',
    required: true,
    includeIfNull: false,
  )
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKey &&
          other.name == name &&
          other.permissions == permissions &&
          other.revokedAt == revokedAt &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url;

  @override
  int get hashCode =>
      name.hashCode +
      permissions.hashCode +
      (revokedAt == null ? 0 : revokedAt.hashCode) +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode;

  factory ApiKey.fromJson(Map<String, dynamic> json) => _$ApiKeyFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
