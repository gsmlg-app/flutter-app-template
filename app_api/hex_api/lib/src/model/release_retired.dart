//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'release_retired.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReleaseRetired {
  /// Returns a new [ReleaseRetired] instance.
  ReleaseRetired({
    this.reason,
    this.message,
  });

  @JsonKey(
    name: r'reason',
    required: false,
    includeIfNull: false,
  )
  final ReleaseRetiredReasonEnum? reason;

  @JsonKey(
    name: r'message',
    required: false,
    includeIfNull: false,
  )
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseRetired &&
          other.reason == reason &&
          other.message == message;

  @override
  int get hashCode => reason.hashCode + message.hashCode;

  factory ReleaseRetired.fromJson(Map<String, dynamic> json) =>
      _$ReleaseRetiredFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseRetiredToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReleaseRetiredReasonEnum {
  @JsonValue(r'other')
  other(r'other'),
  @JsonValue(r'invalid')
  invalid(r'invalid'),
  @JsonValue(r'security')
  security(r'security'),
  @JsonValue(r'deprecated')
  deprecated(r'deprecated'),
  @JsonValue(r'renamed')
  renamed(r'renamed');

  const ReleaseRetiredReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
