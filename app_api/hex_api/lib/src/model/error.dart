//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'error.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Error {
  /// Returns a new [Error] instance.
  Error({
    this.status,
    this.message,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error && other.status == status && other.message == message;

  @override
  int get hashCode => status.hashCode + message.hashCode;

  factory Error.fromJson(Map<String, dynamic> json) => _$ErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
