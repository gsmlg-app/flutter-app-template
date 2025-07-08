//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'release_meta.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReleaseMeta {
  /// Returns a new [ReleaseMeta] instance.
  ReleaseMeta({
    this.buildTools,
  });

  @JsonKey(
    name: r'build_tools',
    required: false,
    includeIfNull: false,
  )
  final List<String>? buildTools;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseMeta && other.buildTools == buildTools;

  @override
  int get hashCode => buildTools.hashCode;

  factory ReleaseMeta.fromJson(Map<String, dynamic> json) =>
      _$ReleaseMetaFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseMetaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
