# hex_api.api.UsersApi

## Load the API package
```dart
import 'package:hex_api/api.dart';
```

All URIs are relative to *https://hex.pm/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createUser**](UsersApi.md#createuser) | **POST** /users | Create a User
[**getCurrentUser**](UsersApi.md#getcurrentuser) | **GET** /users/me | Fetch Currently Authenticated User
[**getUser**](UsersApi.md#getuser) | **GET** /users/{username_or_email} | Fetch a User
[**resetUserPassword**](UsersApi.md#resetuserpassword) | **POST** /users/{username_or_email}/reset | Reset User Password


# **createUser**
> User createUser(userCreate)

Create a User

Creates a new user. A confirmation email with an activation link is sent to the provided email address.  The account must be activated before it can be used.  Clients must display a link to the Hex Terms of Service.

### Example
```dart
import 'package:hex_api/api.dart';

final api = HexApi().getUsersApi();
final UserCreate userCreate = ; // UserCreate | 

try {
    final response = api.createUser(userCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->createUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userCreate** | [**UserCreate**](UserCreate.md)|  | 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCurrentUser**
> UserWithOrgs getCurrentUser()

Fetch Currently Authenticated User

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getUsersApi();

try {
    final response = api.getCurrentUser();
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->getCurrentUser: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserWithOrgs**](UserWithOrgs.md)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUser**
> User getUser(usernameOrEmail)

Fetch a User

### Example
```dart
import 'package:hex_api/api.dart';

final api = HexApi().getUsersApi();
final String usernameOrEmail = usernameOrEmail_example; // String | The username or primary email address of the user.

try {
    final response = api.getUser(usernameOrEmail);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->getUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usernameOrEmail** | **String**| The username or primary email address of the user. | 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetUserPassword**
> resetUserPassword(usernameOrEmail)

Reset User Password

Initiates the password reset process. An email with a reset link will be sent to the user's primary email address.

### Example
```dart
import 'package:hex_api/api.dart';
// TODO Configure API key authorization: apiTokenAuth
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('apiTokenAuth').apiKeyPrefix = 'Bearer';

final api = HexApi().getUsersApi();
final String usernameOrEmail = usernameOrEmail_example; // String | The username or email address of the user.

try {
    api.resetUserPassword(usernameOrEmail);
} catch on DioException (e) {
    print('Exception when calling UsersApi->resetUserPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usernameOrEmail** | **String**| The username or email address of the user. | 

### Return type

void (empty response body)

### Authorization

[apiTokenAuth](../README.md#apiTokenAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

