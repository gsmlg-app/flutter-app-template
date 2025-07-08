//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'user_with_orgs_all_of_organizations.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserWithOrgsAllOfOrganizations {
  /// Returns a new [UserWithOrgsAllOfOrganizations] instance.
  UserWithOrgsAllOfOrganizations({
    required this.name,
    required this.role,
  });

  /// Name of the organization.
  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  /// User's role in the organization.
  @JsonKey(
    name: r'role',
    required: true,
    includeIfNull: false,
  )
  final String role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserWithOrgsAllOfOrganizations &&
          other.name == name &&
          other.role == role;

  @override
  int get hashCode => name.hashCode + role.hashCode;

  factory UserWithOrgsAllOfOrganizations.fromJson(Map<String, dynamic> json) =>
      _$UserWithOrgsAllOfOrganizationsFromJson(json);

  Map<String, dynamic> toJson() => _$UserWithOrgsAllOfOrganizationsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
