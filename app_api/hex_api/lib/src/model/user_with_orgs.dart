//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hex_api/src/model/user_with_orgs_all_of_organizations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_with_orgs.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserWithOrgs {
  /// Returns a new [UserWithOrgs] instance.
  UserWithOrgs({
    required this.username,
    required this.email,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
    required this.organizations,
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

  @JsonKey(
    name: r'organizations',
    required: true,
    includeIfNull: false,
  )
  final List<UserWithOrgsAllOfOrganizations> organizations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserWithOrgs &&
          other.username == username &&
          other.email == email &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url &&
          other.organizations == organizations;

  @override
  int get hashCode =>
      username.hashCode +
      email.hashCode +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode +
      organizations.hashCode;

  factory UserWithOrgs.fromJson(Map<String, dynamic> json) =>
      _$UserWithOrgsFromJson(json);

  Map<String, dynamic> toJson() => _$UserWithOrgsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
