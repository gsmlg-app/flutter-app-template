import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for PackageDocumentationApi
void main() {
  final instance = HexApi().getPackageDocumentationApi();

  group(PackageDocumentationApi, () {
    // Remove Package Documentation
    //
    //Future deleteDocs(String name, String version) async
    test('test deleteDocs', () async {
      // TODO
    });

    // Publish Package Documentation
    //
    // Upload documentation for a specific package release. The body must be a gzipped tarball containing the documentation files, including an `index.html`.
    //
    //Future publishDocs(String name, String version, MultipartFile body) async
    test('test publishDocs', () async {
      // TODO
    });
  });
}
