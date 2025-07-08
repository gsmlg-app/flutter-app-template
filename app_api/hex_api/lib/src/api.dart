//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:hex_api/src/auth/api_key_auth.dart';
import 'package:hex_api/src/auth/basic_auth.dart';
import 'package:hex_api/src/auth/bearer_auth.dart';
import 'package:hex_api/src/auth/oauth.dart';
import 'package:hex_api/src/api/api_keys_api.dart';
import 'package:hex_api/src/api/package_documentation_api.dart';
import 'package:hex_api/src/api/package_owners_api.dart';
import 'package:hex_api/src/api/package_releases_api.dart';
import 'package:hex_api/src/api/packages_api.dart';
import 'package:hex_api/src/api/repositories_api.dart';
import 'package:hex_api/src/api/users_api.dart';

class HexApi {
  static const String basePath = r'https://hex.pm/api';

  final Dio dio;
  HexApi({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  }) : this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
              as OAuthInterceptor)
          .tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
              as BearerAuthInterceptor)
          .tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this
                  .dio
                  .interceptors
                  .firstWhere((element) => element is ApiKeyAuthInterceptor)
              as ApiKeyAuthInterceptor)
          .apiKeys[name] = apiKey;
    }
  }

  /// Get APIKeysApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  APIKeysApi getAPIKeysApi() {
    return APIKeysApi(dio);
  }

  /// Get PackageDocumentationApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PackageDocumentationApi getPackageDocumentationApi() {
    return PackageDocumentationApi(dio);
  }

  /// Get PackageOwnersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PackageOwnersApi getPackageOwnersApi() {
    return PackageOwnersApi(dio);
  }

  /// Get PackageReleasesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PackageReleasesApi getPackageReleasesApi() {
    return PackageReleasesApi(dio);
  }

  /// Get PackagesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PackagesApi getPackagesApi() {
    return PackagesApi(dio);
  }

  /// Get RepositoriesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RepositoriesApi getRepositoriesApi() {
    return RepositoriesApi(dio);
  }

  /// Get UsersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  UsersApi getUsersApi() {
    return UsersApi(dio);
  }
}
