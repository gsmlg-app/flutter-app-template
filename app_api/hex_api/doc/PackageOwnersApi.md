# hex_api.api.PackageOwnersApi

## Load the API package
```dart
import 'package:hex_api/api.dart';
```

All URIs are relative to *https://hex.pm/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addOwner**](PackageOwnersApi.md#addowner) | **PUT** /packages/{name}/owners/{email} | Add a Package Owner
[**getOwners**](PackageOwnersApi.md#getowners) | **GET** /packages/{name}/owners | Fetch Package Owners
[**removeOwner**](PackageOwnersApi.md#removeowner) | **DELETE** /packages/{name}/owners/{email} | Remove a Package Owner


# **addOwner**
> addOwner(name, email, addOwnerRequest)

Add a Package Owner

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getPackageOwnersApi();
final String name = name_example; // String | The package name.
final String email = email_example; // String | The email address of the user to add as an owner.
final AddOwnerRequest addOwnerRequest = ; // AddOwnerRequest | 

try {
    api.addOwner(name, email, addOwnerRequest);
} catch on DioException (e) {
    print('Exception when calling PackageOwnersApi->addOwner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The package name. | 
 **email** | **String**| The email address of the user to add as an owner. | 
 **addOwnerRequest** | [**AddOwnerRequest**](AddOwnerRequest.md)|  | [optional] 

### Return type

void (empty response body)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOwners**
> List<Owner> getOwners(name)

Fetch Package Owners

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getPackageOwnersApi();
final String name = name_example; // String | The package name.

try {
    final response = api.getOwners(name);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PackageOwnersApi->getOwners: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The package name. | 

### Return type

[**List&lt;Owner&gt;**](Owner.md)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeOwner**
> removeOwner(name, email)

Remove a Package Owner

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getPackageOwnersApi();
final String name = name_example; // String | The package name.
final String email = email_example; // String | The email address of the user to add as an owner.

try {
    api.removeOwner(name, email);
} catch on DioException (e) {
    print('Exception when calling PackageOwnersApi->removeOwner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The package name. | 
 **email** | **String**| The email address of the user to add as an owner. | 

### Return type

void (empty response body)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

