// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_downloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageDownloads _$PackageDownloadsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PackageDownloads',
      json,
      ($checkedConvert) {
        final val = PackageDownloads(
          all: $checkedConvert('all', (v) => (v as num?)?.toInt()),
          week: $checkedConvert('week', (v) => (v as num?)?.toInt()),
          day: $checkedConvert('day', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PackageDownloadsToJson(PackageDownloads instance) =>
    <String, dynamic>{
      if (instance.all case final value?) 'all': value,
      if (instance.week case final value?) 'week': value,
      if (instance.day case final value?) 'day': value,
    };
