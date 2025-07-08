//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'api_key_permissions_inner.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiKeyPermissionsInner {
  /// Returns a new [ApiKeyPermissionsInner] instance.
  ApiKeyPermissionsInner({
    this.domain,
    this.resource,
  });

  @JsonKey(
    name: r'domain',
    required: false,
    includeIfNull: false,
  )
  final ApiKeyPermissionsInnerDomainEnum? domain;

  @JsonKey(
    name: r'resource',
    required: false,
    includeIfNull: false,
  )
  final String? resource;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKeyPermissionsInner &&
          other.domain == domain &&
          other.resource == resource;

  @override
  int get hashCode => domain.hashCode + resource.hashCode;

  factory ApiKeyPermissionsInner.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyPermissionsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyPermissionsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ApiKeyPermissionsInnerDomainEnum {
  @JsonValue(r'api')
  api(r'api'),
  @JsonValue(r'repository')
  repository(r'repository'),
  @JsonValue(r'repositories')
  repositories(r'repositories');

  const ApiKeyPermissionsInnerDomainEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
