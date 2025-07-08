# hex_api.api.PackagesApi

## Load the API package
```dart
import 'package:hex_api/api.dart';
```

All URIs are relative to *https://hex.pm/api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getPackage**](PackagesApi.md#getpackage) | **GET** /packages/{name} | Fetch a Package
[**listPackages**](PackagesApi.md#listpackages) | **GET** /packages | List all Packages


# **getPackage**
> Package getPackage(name)

Fetch a Package

### Example
```dart
import 'package:hex_api/api.dart';

final api = HexApi().getPackagesApi();
final String name = name_example; // String | The name of the package.

try {
    final response = api.getPackage(name);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PackagesApi->getPackage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the package. | 

### Return type

[**Package**](Package.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPackages**
> List<Package> listPackages(sort, search, page)

List all Packages

Returns a paginated list of packages. Results can be sorted and searched.

### Example
```dart
import 'package:hex_api/api.dart';

final api = HexApi().getPackagesApi();
final String sort = sort_example; // String | Field to sort by.
final String search = search_example; // String | Search string. See API documentation for syntax.
final int page = 56; // int | Page number for pagination.

try {
    final response = api.listPackages(sort, search, page);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PackagesApi->listPackages: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sort** | **String**| Field to sort by. | [optional] [default to 'name']
 **search** | **String**| Search string. See API documentation for syntax. | [optional] 
 **page** | **int**| Page number for pagination. | [optional] [default to 1]

### Return type

[**List&lt;Package&gt;**](Package.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

