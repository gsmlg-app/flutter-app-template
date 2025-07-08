// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Release _$ReleaseFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Release',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'version',
            'has_docs',
            'meta',
            'dependencies',
            'downloads',
            'inserted_at',
            'updated_at',
            'url',
            'package_url'
          ],
        );
        final val = Release(
          version: $checkedConvert('version', (v) => v as String),
          hasDocs: $checkedConvert('has_docs', (v) => v as bool),
          meta: $checkedConvert(
              'meta', (v) => ReleaseMeta.fromJson(v as Map<String, dynamic>)),
          dependencies: $checkedConvert(
              'dependencies',
              (v) => (v as List<dynamic>)
                  .map((e) => ReleaseDependenciesInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          retired: $checkedConvert(
              'retired',
              (v) => v == null
                  ? null
                  : ReleaseRetired.fromJson(v as Map<String, dynamic>)),
          downloads: $checkedConvert('downloads', (v) => (v as num).toInt()),
          insertedAt: $checkedConvert(
              'inserted_at', (v) => DateTime.parse(v as String)),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          url: $checkedConvert('url', (v) => v as String),
          packageUrl: $checkedConvert('package_url', (v) => v as String),
          htmlUrl: $checkedConvert('html_url', (v) => v as String?),
          docsHtmlUrl: $checkedConvert('docs_html_url', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'hasDocs': 'has_docs',
        'insertedAt': 'inserted_at',
        'updatedAt': 'updated_at',
        'packageUrl': 'package_url',
        'htmlUrl': 'html_url',
        'docsHtmlUrl': 'docs_html_url'
      },
    );

Map<String, dynamic> _$ReleaseToJson(Release instance) => <String, dynamic>{
      'version': instance.version,
      'has_docs': instance.hasDocs,
      'meta': instance.meta.toJson(),
      'dependencies': instance.dependencies.map((e) => e.toJson()).toList(),
      if (instance.retired?.toJson() case final value?) 'retired': value,
      'downloads': instance.downloads,
      'inserted_at': instance.insertedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'url': instance.url,
      'package_url': instance.packageUrl,
      if (instance.htmlUrl case final value?) 'html_url': value,
      if (instance.docsHtmlUrl case final value?) 'docs_html_url': value,
    };
