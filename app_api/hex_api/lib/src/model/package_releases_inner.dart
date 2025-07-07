//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'package_releases_inner.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackageReleasesInner {
  /// Returns a new [PackageReleasesInner] instance.
  PackageReleasesInner({
    this.version,
    this.url,
  });

  @JsonKey(
    name: r'version',
    required: false,
    includeIfNull: false,
  )
  final String? version;

  @JsonKey(
    name: r'url',
    required: false,
    includeIfNull: false,
  )
  final String? url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageReleasesInner &&
          other.version == version &&
          other.url == url;

  @override
  int get hashCode => version.hashCode + url.hashCode;

  factory PackageReleasesInner.fromJson(Map<String, dynamic> json) =>
      _$PackageReleasesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PackageReleasesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
