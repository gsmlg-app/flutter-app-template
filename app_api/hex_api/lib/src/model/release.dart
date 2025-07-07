//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hex_api/src/model/release_meta.dart';
import 'package:hex_api/src/model/release_dependencies_inner.dart';
import 'package:hex_api/src/model/release_retired.dart';
import 'package:json_annotation/json_annotation.dart';

part 'release.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Release {
  /// Returns a new [Release] instance.
  Release({
    required this.version,
    required this.hasDocs,
    required this.meta,
    required this.dependencies,
    this.retired,
    required this.downloads,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
    required this.packageUrl,
    this.htmlUrl,
    this.docsHtmlUrl,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final String version;

  @JsonKey(
    name: r'has_docs',
    required: true,
    includeIfNull: false,
  )
  final bool hasDocs;

  @JsonKey(
    name: r'meta',
    required: true,
    includeIfNull: false,
  )
  final ReleaseMeta meta;

  @JsonKey(
    name: r'dependencies',
    required: true,
    includeIfNull: false,
  )
  final List<ReleaseDependenciesInner> dependencies;

  @JsonKey(
    name: r'retired',
    required: false,
    includeIfNull: false,
  )
  final ReleaseRetired? retired;

  @JsonKey(
    name: r'downloads',
    required: true,
    includeIfNull: false,
  )
  final int downloads;

  @JsonKey(
    name: r'inserted_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime insertedAt;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @JsonKey(
    name: r'url',
    required: true,
    includeIfNull: false,
  )
  final String url;

  @JsonKey(
    name: r'package_url',
    required: true,
    includeIfNull: false,
  )
  final String packageUrl;

  @JsonKey(
    name: r'html_url',
    required: false,
    includeIfNull: false,
  )
  final String? htmlUrl;

  @JsonKey(
    name: r'docs_html_url',
    required: false,
    includeIfNull: false,
  )
  final String? docsHtmlUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Release &&
          other.version == version &&
          other.hasDocs == hasDocs &&
          other.meta == meta &&
          other.dependencies == dependencies &&
          other.retired == retired &&
          other.downloads == downloads &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url &&
          other.packageUrl == packageUrl &&
          other.htmlUrl == htmlUrl &&
          other.docsHtmlUrl == docsHtmlUrl;

  @override
  int get hashCode =>
      version.hashCode +
      hasDocs.hashCode +
      meta.hashCode +
      dependencies.hashCode +
      retired.hashCode +
      downloads.hashCode +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode +
      packageUrl.hashCode +
      htmlUrl.hashCode +
      docsHtmlUrl.hashCode;

  factory Release.fromJson(Map<String, dynamic> json) =>
      _$ReleaseFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
