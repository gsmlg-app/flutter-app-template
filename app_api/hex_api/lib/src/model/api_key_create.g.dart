// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKeyCreate _$ApiKeyCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ApiKeyCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name'],
        );
        final val = ApiKeyCreate(
          name: $checkedConvert('name', (v) => v as String),
          permissions: $checkedConvert(
              'permissions',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ApiKeyPermissionsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ApiKeyCreateToJson(ApiKeyCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      if (instance.permissions?.map((e) => e.toJson()).toList()
          case final value?)
        'permissions': value,
    };
