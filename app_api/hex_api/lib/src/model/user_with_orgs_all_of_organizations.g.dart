// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_with_orgs_all_of_organizations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserWithOrgsAllOfOrganizations _$UserWithOrgsAllOfOrganizationsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'UserWithOrgsAllOfOrganizations',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name', 'role'],
        );
        final val = UserWithOrgsAllOfOrganizations(
          name: $checkedConvert('name', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserWithOrgsAllOfOrganizationsToJson(
        UserWithOrgsAllOfOrganizations instance) =>
    <String, dynamic>{
      'name': instance.name,
      'role': instance.role,
    };
