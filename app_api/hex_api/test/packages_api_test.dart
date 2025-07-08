import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for PackagesApi
void main() {
  final instance = HexApi().getPackagesApi();

  group(PackagesApi, () {
    // Fetch a Package
    //
    //Future<Package> getPackage(String name) async
    test('test getPackage', () async {
      // TODO
    });

    // List all Packages
    //
    // Returns a paginated list of packages. Results can be sorted and searched.
    //
    //Future<List<Package>> listPackages({ String sort, String search, int page }) async
    test('test listPackages', () async {
      // TODO
    });
  });
}
