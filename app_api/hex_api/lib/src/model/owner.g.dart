// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Owner _$OwnerFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Owner',
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
            'level'
          ],
        );
        final val = Owner(
          username: $checkedConvert('username', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          insertedAt: $checkedConvert(
              'inserted_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          url: $checkedConvert('url', (v) => v as String),
          level: $checkedConvert(
              'level', (v) => $enumDecode(_$OwnerLevelEnumEnumMap, v)),
        );
        return val;
      },
      fieldKeyMap: const {
        'insertedAt': 'inserted_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$OwnerToJson(Owner instance) => <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'url': instance.url,
      'level': _$OwnerLevelEnumEnumMap[instance.level]!,
    };

const _$OwnerLevelEnumEnumMap = {
  OwnerLevelEnum.full: 'full',
  OwnerLevelEnum.maintainer: 'maintainer',
};
