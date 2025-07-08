// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_permissions_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKeyPermissionsInner _$ApiKeyPermissionsInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ApiKeyPermissionsInner',
      json,
      ($checkedConvert) {
        final val = ApiKeyPermissionsInner(
          domain: $checkedConvert(
              'domain',
              (v) => $enumDecodeNullable(
                  _$ApiKeyPermissionsInnerDomainEnumEnumMap, v)),
          resource: $checkedConvert('resource', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ApiKeyPermissionsInnerToJson(
        ApiKeyPermissionsInner instance) =>
    <String, dynamic>{
      if (_$ApiKeyPermissionsInnerDomainEnumEnumMap[instance.domain]
          case final value?)
        'domain': value,
      if (instance.resource case final value?) 'resource': value,
    };

const _$ApiKeyPermissionsInnerDomainEnumEnumMap = {
  ApiKeyPermissionsInnerDomainEnum.api: 'api',
  ApiKeyPermissionsInnerDomainEnum.repository: 'repository',
  ApiKeyPermissionsInnerDomainEnum.repositories: 'repositories',
};
