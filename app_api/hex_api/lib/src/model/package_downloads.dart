//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'package_downloads.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackageDownloads {
  /// Returns a new [PackageDownloads] instance.
  PackageDownloads({
    this.all,
    this.week,
    this.day,
  });

  @JsonKey(
    name: r'all',
    required: false,
    includeIfNull: false,
  )
  final int? all;

  @JsonKey(
    name: r'week',
    required: false,
    includeIfNull: false,
  )
  final int? week;

  @JsonKey(
    name: r'day',
    required: false,
    includeIfNull: false,
  )
  final int? day;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageDownloads &&
          other.all == all &&
          other.week == week &&
          other.day == day;

  @override
  int get hashCode => all.hashCode + week.hashCode + day.hashCode;

  factory PackageDownloads.fromJson(Map<String, dynamic> json) =>
      _$PackageDownloadsFromJson(json);

  Map<String, dynamic> toJson() => _$PackageDownloadsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
