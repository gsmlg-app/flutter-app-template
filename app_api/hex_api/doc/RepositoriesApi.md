# hex_api.api.RepositoriesApi

## Load the API package
```dart
import 'package:hex_api/api.dart';
```

All URIs are relative to *https://hex.pm/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getRepo**](RepositoriesApi.md#getrepo) | **GET** /repos/{name} | Fetch a Repository
[**listRepos**](RepositoriesApi.md#listrepos) | **GET** /repos | List all Repositories


# **getRepo**
> Repository getRepo(name)

Fetch a Repository

### Example
```dart
import 'package:hex_api/api.dart';

final api = HexApi().getRepositoriesApi();
final String name = name_example; // String | 

try {
    final response = api.getRepo(name);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RepositoriesApi->getRepo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**|  | 

### Return type

[**Repository**](Repository.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRepos**
> List<Repository> listRepos()

List all Repositories

Returns all public repositories and, if authenticated, all repositories the user is a member of.

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getRepositoriesApi();

try {
    final response = api.listRepos();
    print(response);
} catch on DioException (e) {
    print('Exception when calling RepositoriesApi->listRepos: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;Repository&gt;**](Repository.md)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

