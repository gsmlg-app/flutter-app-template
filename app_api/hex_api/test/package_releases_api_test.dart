import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for PackageReleasesApi
void main() {
  final instance = HexApi().getPackageReleasesApi();

  group(PackageReleasesApi, () {
    // Fetch a Release
    //
    //Future<Release> getRelease(String name, String version) async
    test('test getRelease', () async {
      // TODO
    });

    // Publish a Release
    //
    // Publishes a new release version of a package. This will also create the package if it does not exist. The request body must be a package tarball.
    //
    //Future<Release> publishRelease(MultipartFile body) async
    test('test publishRelease', () async {
      // TODO
    });

    // Mark Release as Retired
    //
    //Future retireRelease(String name, String version, RetirementPayload retirementPayload) async
    test('test retireRelease', () async {
      // TODO
    });

    // Unmark Release as Retired
    //
    //Future unretireRelease(String name, String version) async
    test('test unretireRelease', () async {
      // TODO
    });
  });
}
