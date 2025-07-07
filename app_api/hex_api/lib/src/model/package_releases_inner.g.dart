// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_releases_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageReleasesInner _$PackageReleasesInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PackageReleasesInner',
      json,
      ($checkedConvert) {
        final val = PackageReleasesInner(
          version: $checkedConvert('version', (v) => v as String?),
          url: $checkedConvert('url', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PackageReleasesInnerToJson(
        PackageReleasesInner instance) =>
    <String, dynamic>{
      if (instance.version case final value?) 'version': value,
      if (instance.url case final value?) 'url': value,
    };
