//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'owner.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Owner {
  /// Returns a new [Owner] instance.
  Owner({
    required this.username,
    required this.email,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
    required this.level,
  });

  /// User's unique username.
  @JsonKey(
    name: r'username',
    required: true,
    includeIfNull: false,
  )
  final String username;

  /// User's primary email address.
  @JsonKey(
    name: r'email',
    required: true,
    includeIfNull: false,
  )
  final String email;

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

  /// Ownership level. 'full' owners can manage other owners.
  @JsonKey(
    name: r'level',
    required: true,
    includeIfNull: false,
  )
  final OwnerLevelEnum level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Owner &&
          other.username == username &&
          other.email == email &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url &&
          other.level == level;

  @override
  int get hashCode =>
      username.hashCode +
      email.hashCode +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode +
      level.hashCode;

  factory Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);

  Map<String, dynamic> toJson() => _$OwnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Ownership level. 'full' owners can manage other owners.
enum OwnerLevelEnum {
  /// Ownership level. 'full' owners can manage other owners.
  @JsonValue(r'full')
  full(r'full'),

  /// Ownership level. 'full' owners can manage other owners.
  @JsonValue(r'maintainer')
  maintainer(r'maintainer');

  const OwnerLevelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
