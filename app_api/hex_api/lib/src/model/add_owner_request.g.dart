// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_owner_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddOwnerRequest _$AddOwnerRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddOwnerRequest',
      json,
      ($checkedConvert) {
        final val = AddOwnerRequest(
          level: $checkedConvert(
              'level',
              (v) =>
                  $enumDecodeNullable(_$AddOwnerRequestLevelEnumEnumMap, v) ??
                  AddOwnerRequestLevelEnum.maintainer),
        );
        return val;
      },
    );

Map<String, dynamic> _$AddOwnerRequestToJson(AddOwnerRequest instance) =>
    <String, dynamic>{
      if (_$AddOwnerRequestLevelEnumEnumMap[instance.level] case final value?)
        'level': value,
    };

const _$AddOwnerRequestLevelEnumEnumMap = {
  AddOwnerRequestLevelEnum.full: 'full',
  AddOwnerRequestLevelEnum.maintainer: 'maintainer',
};
