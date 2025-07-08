//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hex_api/src/model/package_releases_inner.dart';
import 'package:hex_api/src/model/package_downloads.dart';
import 'package:hex_api/src/model/package_meta.dart';
import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Package {
  /// Returns a new [Package] instance.
  Package({
    required this.name,
    this.repository,
    this.private,
    required this.meta,
    required this.downloads,
    required this.releases,
    required this.insertedAt,
    required this.updatedAt,
    required this.url,
    this.htmlUrl,
    this.docsHtmlUrl,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'repository',
    required: false,
    includeIfNull: false,
  )
  final String? repository;

  @JsonKey(
    name: r'private',
    required: false,
    includeIfNull: false,
  )
  final bool? private;

  @JsonKey(
    name: r'meta',
    required: true,
    includeIfNull: false,
  )
  final PackageMeta meta;

  @JsonKey(
    name: r'downloads',
    required: true,
    includeIfNull: false,
  )
  final PackageDownloads downloads;

  @JsonKey(
    name: r'releases',
    required: true,
    includeIfNull: false,
  )
  final List<PackageReleasesInner> releases;

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
      other is Package &&
          other.name == name &&
          other.repository == repository &&
          other.private == private &&
          other.meta == meta &&
          other.downloads == downloads &&
          other.releases == releases &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt &&
          other.url == url &&
          other.htmlUrl == htmlUrl &&
          other.docsHtmlUrl == docsHtmlUrl;

  @override
  int get hashCode =>
      name.hashCode +
      repository.hashCode +
      private.hashCode +
      meta.hashCode +
      downloads.hashCode +
      releases.hashCode +
      insertedAt.hashCode +
      updatedAt.hashCode +
      url.hashCode +
      htmlUrl.hashCode +
      docsHtmlUrl.hashCode;

  factory Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);

  Map<String, dynamic> toJson() => _$PackageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
