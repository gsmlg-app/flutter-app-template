import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for APIKeysApi
void main() {
  final instance = HexApi().getAPIKeysApi();

  group(APIKeysApi, () {
    // Create an API Key
    //
    // Creates a new API key. This endpoint requires Basic Authentication.  The key's secret is only returned on creation and must be stored securely.
    //
    //Future<ApiKeyWithSecret> createKey(ApiKeyCreate apiKeyCreate) async
    test('test createKey', () async {
      // TODO
    });

    // Fetch an API Key
    //
    //Future<ApiKey> getKey(String name) async
    test('test getKey', () async {
      // TODO
    });

    // List all API Keys
    //
    //Future<List<ApiKey>> listKeys() async
    test('test listKeys', () async {
      // TODO
    });

    // Remove an API Key
    //
    //Future removeKey(String name) async
    test('test removeKey', () async {
      // TODO
    });
  });
}
