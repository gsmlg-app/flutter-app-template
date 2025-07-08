// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_retired.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseRetired _$ReleaseRetiredFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReleaseRetired',
      json,
      ($checkedConvert) {
        final val = ReleaseRetired(
          reason: $checkedConvert('reason',
              (v) => $enumDecodeNullable(_$ReleaseRetiredReasonEnumEnumMap, v)),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReleaseRetiredToJson(ReleaseRetired instance) =>
    <String, dynamic>{
      if (_$ReleaseRetiredReasonEnumEnumMap[instance.reason] case final value?)
        'reason': value,
      if (instance.message case final value?) 'message': value,
    };

const _$ReleaseRetiredReasonEnumEnumMap = {
  ReleaseRetiredReasonEnum.other: 'other',
  ReleaseRetiredReasonEnum.invalid: 'invalid',
  ReleaseRetiredReasonEnum.security: 'security',
  ReleaseRetiredReasonEnum.deprecated: 'deprecated',
  ReleaseRetiredReasonEnum.renamed: 'renamed',
};
