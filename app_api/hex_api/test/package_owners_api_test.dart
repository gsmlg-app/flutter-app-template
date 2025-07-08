import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for PackageOwnersApi
void main() {
  final instance = HexApi().getPackageOwnersApi();

  group(PackageOwnersApi, () {
    // Add a Package Owner
    //
    //Future addOwner(String name, String email, { AddOwnerRequest addOwnerRequest }) async
    test('test addOwner', () async {
      // TODO
    });

    // Fetch Package Owners
    //
    //Future<List<Owner>> getOwners(String name) async
    test('test getOwners', () async {
      // TODO
    });

    // Remove a Package Owner
    //
    //Future removeOwner(String name, String email) async
    test('test removeOwner', () async {
      // TODO
    });
  });
}
