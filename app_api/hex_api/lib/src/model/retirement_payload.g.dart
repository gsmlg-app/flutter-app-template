// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retirement_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RetirementPayload _$RetirementPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RetirementPayload',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['reason'],
        );
        final val = RetirementPayload(
          reason: $checkedConvert('reason',
              (v) => $enumDecode(_$RetirementPayloadReasonEnumEnumMap, v)),
          message: $checkedConvert('message', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RetirementPayloadToJson(RetirementPayload instance) =>
    <String, dynamic>{
      'reason': _$RetirementPayloadReasonEnumEnumMap[instance.reason]!,
      if (instance.message case final value?) 'message': value,
    };

const _$RetirementPayloadReasonEnumEnumMap = {
  RetirementPayloadReasonEnum.other: 'other',
  RetirementPayloadReasonEnum.invalid: 'invalid',
  RetirementPayloadReasonEnum.security: 'security',
  RetirementPayloadReasonEnum.deprecated: 'deprecated',
  RetirementPayloadReasonEnum.renamed: 'renamed',
};
