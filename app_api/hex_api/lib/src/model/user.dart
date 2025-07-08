//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class User {
  /// Returns a new [User] instance.
  User({
    required this.username,
    required this.email,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.username == username &&
          other.email == email &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url;

  @override
  int get hashCode =>
      username.hashCode +
      email.hashCode +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
