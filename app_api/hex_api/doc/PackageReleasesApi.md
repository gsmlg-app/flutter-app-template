# hex_api.api.PackageReleasesApi

## Load the API package
```dart
import 'package:hex_api/api.dart';
```

All URIs are relative to *https://hex.pm/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getRelease**](PackageReleasesApi.md#getrelease) | **GET** /packages/{name}/releases/{version} | Fetch a Release
[**publishRelease**](PackageReleasesApi.md#publishrelease) | **POST** /publish | Publish a Release
[**retireRelease**](PackageReleasesApi.md#retirerelease) | **POST** /packages/{name}/releases/{version}/retire | Mark Release as Retired
[**unretireRelease**](PackageReleasesApi.md#unretirerelease) | **DELETE** /packages/{name}/releases/{version}/retire | Unmark Release as Retired


# **getRelease**
> Release getRelease(name, version)

Fetch a Release

### Example
```dart
import 'package:hex_api/api.dart';

final api = HexApi().getPackageReleasesApi();
final String name = name_example; // String | The name of the package.
final String version = version_example; // String | The release version.

try {
    final response = api.getRelease(name, version);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PackageReleasesApi->getRelease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the package. | 
 **version** | **String**| The release version. | 

### Return type

[**Release**](Release.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publishRelease**
> Release publishRelease(body)

Publish a Release

Publishes a new release version of a package. This will also create the package if it does not exist. The request body must be a package tarball.

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getPackageReleasesApi();
final MultipartFile body = BINARY_DATA_HERE; // MultipartFile | A gzipped tarball containing the package contents.

try {
    final response = api.publishRelease(body);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PackageReleasesApi->publishRelease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **MultipartFile**| A gzipped tarball containing the package contents. | 

### Return type

[**Release**](Release.md)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: application/gzip
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **retireRelease**
> retireRelease(name, version, retirementPayload)

Mark Release as Retired

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getPackageReleasesApi();
final String name = name_example; // String | The package name.
final String version = version_example; // String | The release version.
final RetirementPayload retirementPayload = ; // RetirementPayload | 

try {
    api.retireRelease(name, version, retirementPayload);
} catch on DioException (e) {
    print('Exception when calling PackageReleasesApi->retireRelease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The package name. | 
 **version** | **String**| The release version. | 
 **retirementPayload** | [**RetirementPayload**](RetirementPayload.md)|  | 

### Return type

void (empty response body)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unretireRelease**
> unretireRelease(name, version)

Unmark Release as Retired

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getPackageReleasesApi();
final String name = name_example; // String | The package name.
final String version = version_example; // String | The release version.

try {
    api.unretireRelease(name, version);
} catch on DioException (e) {
    print('Exception when calling PackageReleasesApi->unretireRelease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The package name. | 
 **version** | **String**| The release version. | 

### Return type

void (empty response body)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

