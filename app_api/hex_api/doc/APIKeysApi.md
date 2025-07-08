# hex_api.api.APIKeysApi

## Load the API package
```dart
import 'package:hex_api/api.dart';
```

All URIs are relative to *https://hex.pm/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createKey**](APIKeysApi.md#createkey) | **POST** /keys | Create an API Key
[**getKey**](APIKeysApi.md#getkey) | **GET** /keys/{name} | Fetch an API Key
[**listKeys**](APIKeysApi.md#listkeys) | **GET** /keys | List all API Keys
[**removeKey**](APIKeysApi.md#removekey) | **DELETE** /keys/{name} | Remove an API Key


# **createKey**
> ApiKeyWithSecret createKey(apiKeyCreate)

Create an API Key

Creates a new API key. This endpoint requires Basic Authentication.  The key's secret is only returned on creation and must be stored securely.

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure HTTP basic authorization: basicAuth
//defaultApiClient.getAuthentication<HttpBasicAuth>('basicAuth').username = 'YOUR_USERNAME'
//defaultApiClient.getAuthentication<HttpBasicAuth>('basicAuth').password = 'YOUR_PASSWORD';

final api = HexApi().getAPIKeysApi();
final ApiKeyCreate apiKeyCreate = ; // ApiKeyCreate | 

try {
    final response = api.createKey(apiKeyCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling APIKeysApi->createKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKeyCreate** | [**ApiKeyCreate**](ApiKeyCreate.md)|  | 

### Return type

[**ApiKeyWithSecret**](ApiKeyWithSecret.md)

### Authorization

[basicAuth](../README.md#basicAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getKey**
> ApiKey getKey(name)

Fetch an API Key

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getAPIKeysApi();
final String name = name_example; // String | The name of the API key.

try {
    final response = api.getKey(name);
    print(response);
} catch on DioException (e) {
    print('Exception when calling APIKeysApi->getKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the API key. | 

### Return type

[**ApiKey**](ApiKey.md)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listKeys**
> List<ApiKey> listKeys()

List all API Keys

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getAPIKeysApi();

try {
    final response = api.listKeys();
    print(response);
} catch on DioException (e) {
    print('Exception when calling APIKeysApi->listKeys: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;ApiKey&gt;**](ApiKey.md)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeKey**
> removeKey(name)

Remove an API Key

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getAPIKeysApi();
final String name = name_example; // String | The name of the API key.

try {
    api.removeKey(name);
} catch on DioException (e) {
    print('Exception when calling APIKeysApi->removeKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the API key. | 

### Return type

void (empty response body)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

