//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'package_meta.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackageMeta {
  /// Returns a new [PackageMeta] instance.
  PackageMeta({
    this.description,
    this.licenses,
    this.links,
  });

  @JsonKey(
    name: r'description',
    required: false,
    includeIfNull: false,
  )
  final String? description;

  @JsonKey(
    name: r'licenses',
    required: false,
    includeIfNull: false,
  )
  final List<String>? licenses;

  @JsonKey(
    name: r'links',
    required: false,
    includeIfNull: false,
  )
  final Map<String, String>? links;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageMeta &&
          other.description == description &&
          other.licenses == licenses &&
          other.links == links;

  @override
  int get hashCode => description.hashCode + licenses.hashCode + links.hashCode;

  factory PackageMeta.fromJson(Map<String, dynamic> json) =>
      _$PackageMetaFromJson(json);

  Map<String, dynamic> toJson() => _$PackageMetaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
