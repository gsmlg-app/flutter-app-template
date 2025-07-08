//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'retirement_payload.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RetirementPayload {
  /// Returns a new [RetirementPayload] instance.
  RetirementPayload({
    required this.reason,
    this.message,
  });

  /// Reason for retiring the release.
  @JsonKey(
    name: r'reason',
    required: true,
    includeIfNull: false,
  )
  final RetirementPayloadReasonEnum reason;

  /// An additional, clarifying message for the retirement.
  @JsonKey(
    name: r'message',
    required: false,
    includeIfNull: false,
  )
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetirementPayload &&
          other.reason == reason &&
          other.message == message;

  @override
  int get hashCode => reason.hashCode + message.hashCode;

  factory RetirementPayload.fromJson(Map<String, dynamic> json) =>
      _$RetirementPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RetirementPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Reason for retiring the release.
enum RetirementPayloadReasonEnum {
  /// Reason for retiring the release.
  @JsonValue(r'other')
  other(r'other'),

  /// Reason for retiring the release.
  @JsonValue(r'invalid')
  invalid(r'invalid'),

  /// Reason for retiring the release.
  @JsonValue(r'security')
  security(r'security'),

  /// Reason for retiring the release.
  @JsonValue(r'deprecated')
  deprecated(r'deprecated'),

  /// Reason for retiring the release.
  @JsonValue(r'renamed')
  renamed(r'renamed');

  const RetirementPayloadReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
