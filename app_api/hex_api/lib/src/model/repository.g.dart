// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repository _$RepositoryFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Repository',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'name',
            'public',
            'active',
            'billing_active',
            'inserted_at',
            'updated_at'
          ],
        );
        final val = Repository(
          name: $checkedConvert('name', (v) => v as String),
          public: $checkedConvert('public', (v) => v as bool),
          active: $checkedConvert('active', (v) => v as bool),
          billingActive: $checkedConvert('billing_active', (v) => v as bool),
          insertedAt: $checkedConvert(
              'inserted_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'billingActive': 'billing_active',
        'insertedAt': 'inserted_at',
        'updatedAt': 'updated_at'
      },
    );

Map<String, dynamic> _$RepositoryToJson(Repository instance) =>
    <String, dynamic>{
      'name': instance.name,
      'public': instance.public,
      'active': instance.active,
      'billing_active': instance.billingActive,
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
