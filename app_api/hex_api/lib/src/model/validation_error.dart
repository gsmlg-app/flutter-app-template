//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'validation_error.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ValidationError {
  /// Returns a new [ValidationError] instance.
  ValidationError({
    this.status,
    this.message,
    this.errors,
  });

  @JsonKey(
    name: r'status',
    required: false,
    includeIfNull: false,
  )
  final int? status;

  @JsonKey(
    name: r'message',
    required: false,
    includeIfNull: false,
  )
  final String? message;

  @JsonKey(
    name: r'errors',
    required: false,
    includeIfNull: false,
  )
  final Map<String, String>? errors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          other.status == status &&
          other.message == message &&
          other.errors == errors;

  @override
  int get hashCode => status.hashCode + message.hashCode + errors.hashCode;

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
