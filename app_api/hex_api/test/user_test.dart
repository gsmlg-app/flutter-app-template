import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';
import 'dart:io';

// tests for User
void main() async {
  final hexApi = HexApi();
  final String? token = Platform.environment['HEX_API_KEY'];
  hexApi.setBearerAuth('user', token ?? 'N/A');
  final userApi = hexApi.getUsersApi();
  final resp = await userApi.getCurrentUser();
  final UserWithOrgs? instance = resp.data;

  group(User, () {
    // User's unique username.
    // String username
    test('to test the property `username`', () async {
      expect(instance?.username, isNotNull);
    });

    // User's primary email address.
    // String email
    test('to test the property `email`', () async {
      expect(instance?.email, isNotNull);
    });

    // DateTime insertedAt
    test('to test the property `insertedAt`', () async {
      expect(instance?.insertedAt, isNotNull);
    });

    // DateTime updatedAt
    test('to test the property `updatedAt`', () async {
      expect(instance?.updatedAt, isNotNull);
    });

    // String url
    test('to test the property `url`', () async {
      expect(instance?.url, isNotNull);
    });
  });
}
