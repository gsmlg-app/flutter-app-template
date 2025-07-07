//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'release_dependencies_inner.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReleaseDependenciesInner {
  /// Returns a new [ReleaseDependenciesInner] instance.
  ReleaseDependenciesInner({
    this.name,
    this.requirement,
    this.optional,
    this.app,
  });

  @JsonKey(
    name: r'name',
    required: false,
    includeIfNull: false,
  )
  final String? name;

  @JsonKey(
    name: r'requirement',
    required: false,
    includeIfNull: false,
  )
  final String? requirement;

  @JsonKey(
    name: r'optional',
    required: false,
    includeIfNull: false,
  )
  final bool? optional;

  @JsonKey(
    name: r'app',
    required: false,
    includeIfNull: false,
  )
  final String? app;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseDependenciesInner &&
          other.name == name &&
          other.requirement == requirement &&
          other.optional == optional &&
          other.app == app;

  @override
  int get hashCode =>
      name.hashCode + requirement.hashCode + optional.hashCode + app.hashCode;

  factory ReleaseDependenciesInner.fromJson(Map<String, dynamic> json) =>
      _$ReleaseDependenciesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseDependenciesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
