// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseMeta _$ReleaseMetaFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ReleaseMeta',
      json,
      ($checkedConvert) {
        final val = ReleaseMeta(
          buildTools: $checkedConvert('build_tools',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {'buildTools': 'build_tools'},
    );

Map<String, dynamic> _$ReleaseMetaToJson(ReleaseMeta instance) =>
    <String, dynamic>{
      if (instance.buildTools case final value?) 'build_tools': value,
    };
