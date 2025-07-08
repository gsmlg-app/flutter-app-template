# hex_api.model.ApiKeyWithSecret

## Load the model package
```dart
import 'package:hex_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | 
**permissions** | [**List&lt;ApiKeyPermissionsInner&gt;**](ApiKeyPermissionsInner.md) |  | 
**revokedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**insertedAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**url** | **String** |  | 
**secret** | **String** | The key secret, a 32 character hex encoded string. Only returned on creation. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


