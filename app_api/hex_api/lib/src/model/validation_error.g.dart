// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationError _$ValidationErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ValidationError',
      json,
      ($checkedConvert) {
        final val = ValidationError(
          status: $checkedConvert('status', (v) => (v as num?)?.toInt()),
          message: $checkedConvert('message', (v) => v as String?),
          errors: $checkedConvert(
              'errors',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as String),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      if (instance.status case final value?) 'status': value,
      if (instance.message case final value?) 'message': value,
      if (instance.errors case final value?) 'errors': value,
    };
