//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'add_owner_request.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddOwnerRequest {
  /// Returns a new [AddOwnerRequest] instance.
  AddOwnerRequest({
    this.level = const AddOwnerRequestLevelEnum._('maintainer'),
  });

  @JsonKey(
    defaultValue: 'maintainer',
    name: r'level',
    required: false,
    includeIfNull: false,
  )
  final AddOwnerRequestLevelEnum? level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddOwnerRequest && other.level == level;

  @override
  int get hashCode => level.hashCode;

  factory AddOwnerRequest.fromJson(Map<String, dynamic> json) =>
      _$AddOwnerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddOwnerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AddOwnerRequestLevelEnum {
  @JsonValue(r'full')
  full(r'full'),
  @JsonValue(r'maintainer')
  maintainer(r'maintainer');

  const AddOwnerRequestLevelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
