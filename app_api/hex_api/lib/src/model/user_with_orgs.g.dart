// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_with_orgs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserWithOrgs _$UserWithOrgsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UserWithOrgs',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'username',
            'email',
            'inserted_at',
            'updated_at',
            'url',
            'organizations'
          ],
        );
        final val = UserWithOrgs(
          username: $checkedConvert('username', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          insertedAt: $checkedConvert(
              'inserted_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          url: $checkedConvert('url', (v) => v as String),
          organizations: $checkedConvert(
              'organizations',
              (v) => (v as List<dynamic>)
                  .map((e) => UserWithOrgsAllOfOrganizations.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'insertedAt': 'inserted_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$UserWithOrgsToJson(UserWithOrgs instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'url': instance.url,
      'organizations': instance.organizations.map((e) => e.toJson()).toList(),
    };
