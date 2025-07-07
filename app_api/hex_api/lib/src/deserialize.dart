import 'package:hex_api/src/model/add_owner_request.dart';
import 'package:hex_api/src/model/api_key.dart';
import 'package:hex_api/src/model/api_key_create.dart';
import 'package:hex_api/src/model/api_key_permissions_inner.dart';
import 'package:hex_api/src/model/api_key_with_secret.dart';
import 'package:hex_api/src/model/error.dart';
import 'package:hex_api/src/model/owner.dart';
import 'package:hex_api/src/model/package.dart';
import 'package:hex_api/src/model/package_downloads.dart';
import 'package:hex_api/src/model/package_meta.dart';
import 'package:hex_api/src/model/package_releases_inner.dart';
import 'package:hex_api/src/model/release.dart';
import 'package:hex_api/src/model/release_dependencies_inner.dart';
import 'package:hex_api/src/model/release_meta.dart';
import 'package:hex_api/src/model/release_retired.dart';
import 'package:hex_api/src/model/repository.dart';
import 'package:hex_api/src/model/retirement_payload.dart';
import 'package:hex_api/src/model/user.dart';
import 'package:hex_api/src/model/user_create.dart';
import 'package:hex_api/src/model/user_with_orgs.dart';
import 'package:hex_api/src/model/user_with_orgs_all_of_organizations.dart';
import 'package:hex_api/src/model/validation_error.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType,
    {bool growable = true}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AddOwnerRequest':
      return AddOwnerRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ApiKey':
      return ApiKey.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ApiKeyCreate':
      return ApiKeyCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ApiKeyPermissionsInner':
      return ApiKeyPermissionsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ApiKeyWithSecret':
      return ApiKeyWithSecret.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Error':
      return Error.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Owner':
      return Owner.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Package':
      return Package.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PackageDownloads':
      return PackageDownloads.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PackageMeta':
      return PackageMeta.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PackageReleasesInner':
      return PackageReleasesInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Release':
      return Release.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReleaseDependenciesInner':
      return ReleaseDependenciesInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReleaseMeta':
      return ReleaseMeta.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReleaseRetired':
      return ReleaseRetired.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Repository':
      return Repository.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RetirementPayload':
      return RetirementPayload.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'User':
      return User.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UserCreate':
      return UserCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UserWithOrgs':
      return UserWithOrgs.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UserWithOrgsAllOfOrganizations':
      return UserWithOrgsAllOfOrganizations.fromJson(
          value as Map<String, dynamic>) as ReturnType;
    case 'ValidationError':
      return ValidationError.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toList(growable: growable) as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
            .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(
                v, targetType,
                growable: growable))
            .toSet() as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map((dynamic v) => deserialize<BaseType, BaseType>(
              v, targetType,
              growable: growable)),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
