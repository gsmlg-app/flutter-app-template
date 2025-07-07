//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'user_create.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserCreate {
  /// Returns a new [UserCreate] instance.
  UserCreate({
    required this.username,
    required this.password,
    required this.email,
  });

  /// Alphanumeric characters, underscores, hyphens, and dots. Case insensitive.
  @JsonKey(
    name: r'username',
    required: true,
    includeIfNull: false,
  )
  final String username;

  /// A printable UTF-8 string.
  @JsonKey(
    name: r'password',
    required: true,
    includeIfNull: false,
  )
  final String password;

  @JsonKey(
    name: r'email',
    required: true,
    includeIfNull: false,
  )
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCreate &&
          other.username == username &&
          other.password == password &&
          other.email == email;

  @override
  int get hashCode => username.hashCode + password.hashCode + email.hashCode;

  factory UserCreate.fromJson(Map<String, dynamic> json) =>
      _$UserCreateFromJson(json);

  Map<String, dynamic> toJson() => _$UserCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
