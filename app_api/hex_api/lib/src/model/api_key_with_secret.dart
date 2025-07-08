//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hex_api/src/model/api_key_permissions_inner.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_key_with_secret.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiKeyWithSecret {
  /// Returns a new [ApiKeyWithSecret] instance.
  ApiKeyWithSecret({
    required this.name,
    required this.permissions,
    this.revokedAt,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
    required this.secret,
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

  /// The key secret, a 32 character hex encoded string. Only returned on creation.
  @JsonKey(
    name: r'secret',
    required: true,
    includeIfNull: false,
  )
  final String secret;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKeyWithSecret &&
          other.name == name &&
          other.permissions == permissions &&
          other.revokedAt == revokedAt &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url &&
          other.secret == secret;

  @override
  int get hashCode =>
      name.hashCode +
      permissions.hashCode +
      (revokedAt == null ? 0 : revokedAt.hashCode) +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode +
      secret.hashCode;

  factory ApiKeyWithSecret.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyWithSecretFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyWithSecretToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
