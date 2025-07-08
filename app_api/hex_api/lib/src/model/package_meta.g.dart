// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageMeta _$PackageMetaFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PackageMeta',
      json,
      ($checkedConvert) {
        final val = PackageMeta(
          description: $checkedConvert('description', (v) => v as String?),
          licenses: $checkedConvert('licenses',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          links: $checkedConvert(
              'links',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as String),
                  )),
        );
        return val;
      },
    );

Map<String, dynamic> _$PackageMetaToJson(PackageMeta instance) =>
    <String, dynamic>{
      if (instance.description case final value?) 'description': value,
      if (instance.licenses case final value?) 'licenses': value,
      if (instance.links case final value?) 'links': value,
    };
