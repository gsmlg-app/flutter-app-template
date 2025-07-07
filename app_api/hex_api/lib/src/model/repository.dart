//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'repository.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Repository {
  /// Returns a new [Repository] instance.
  Repository({
    required this.name,
    required this.public,
    required this.active,
    required this.billingActive,
    required this.insertedAt,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'public',
    required: true,
    includeIfNull: false,
  )
  final bool public;

  @JsonKey(
    name: r'active',
    required: true,
    includeIfNull: false,
  )
  final bool active;

  @JsonKey(
    name: r'billing_active',
    required: true,
    includeIfNull: false,
  )
  final bool billingActive;

  @JsonKey(
    name: r'inserted_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime insertedAt;

  @JsonKey(
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Repository &&
          other.name == name &&
          other.public == public &&
          other.active == active &&
          other.billingActive == billingActive &&
          other.insertedAt == insertedAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      name.hashCode +
      public.hashCode +
      active.hashCode +
      billingActive.hashCode +
      insertedAt.hashCode +
      updatedAt.hashCode;

  factory Repository.fromJson(Map<String, dynamic> json) =>
      _$RepositoryFromJson(json);

  Map<String, dynamic> toJson() => _$RepositoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
