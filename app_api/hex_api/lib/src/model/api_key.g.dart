// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKey _$ApiKeyFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ApiKey',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'name',
            'permissions',
            'inserted_at',
            'updated_at',
            'url'
          ],
        );
        final val = ApiKey(
          name: $checkedConvert('name', (v) => v as String),
          permissions: $checkedConvert(
              'permissions',
              (v) => (v as List<dynamic>)
                  .map((e) => ApiKeyPermissionsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          revokedAt: $checkedConvert('revoked_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          insertedAt: $checkedConvert(
              'inserted_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          url: $checkedConvert('url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'revokedAt': 'revoked_at',
        'insertedAt': 'inserted_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$ApiKeyToJson(ApiKey instance) => <String, dynamic>{
      'name': instance.name,
      'permissions': instance.permissions.map((e) => e.toJson()).toList(),
      if (instance.revokedAt?.toIso8601String() case final value?)
        'revoked_at': value,
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'url': instance.url,
    };
