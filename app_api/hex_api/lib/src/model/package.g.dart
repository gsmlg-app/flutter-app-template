// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Package _$PackageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Package',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'name',
            'meta',
            'downloads',
            'releases',
            'inserted_at',
            'updated_at',
            'url'
          ],
        );
        final val = Package(
          name: $checkedConvert('name', (v) => v as String),
          repository: $checkedConvert('repository', (v) => v as String?),
          private: $checkedConvert('private', (v) => v as bool?),
          meta: $checkedConvert(
              'meta', (v) => PackageMeta.fromJson(v as Map<String, dynamic>)),
          downloads: $checkedConvert('downloads',
              (v) => PackageDownloads.fromJson(v as Map<String, dynamic>)),
          releases: $checkedConvert(
              'releases',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      PackageReleasesInner.fromJson(e as Map<String, dynamic>))
                  .toList()),
          insertedAt: $checkedConvert(
              'inserted_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          url: $checkedConvert('url', (v) => v as String),
          htmlUrl: $checkedConvert('html_url', (v) => v as String?),
          docsHtmlUrl: $checkedConvert('docs_html_url', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'insertedAt': 'inserted_at',
        'updatedAt': 'updated_at',
        'htmlUrl': 'html_url',
        'docsHtmlUrl': 'docs_html_url'
      },
    );

Map<String, dynamic> _$PackageToJson(Package instance) => <String, dynamic>{
      'name': instance.name,
      if (instance.repository case final value?) 'repository': value,
      if (instance.private case final value?) 'private': value,
      'meta': instance.meta.toJson(),
      'downloads': instance.downloads.toJson(),
      'releases': instance.releases.map((e) => e.toJson()).toList(),
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'url': instance.url,
      if (instance.htmlUrl case final value?) 'html_url': value,
      if (instance.docsHtmlUrl case final value?) 'docs_html_url': value,
    };
