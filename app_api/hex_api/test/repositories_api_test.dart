import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for RepositoriesApi
void main() {
  final instance = HexApi().getRepositoriesApi();

  group(RepositoriesApi, () {
    // Fetch a Repository
    //
    //Future<Repository> getRepo(String name) async
    test('test getRepo', () async {
      // TODO
    });

    // List all Repositories
    //
    // Returns all public repositories and, if authenticated, all repositories the user is a member of.
    //
    //Future<List<Repository>> listRepos() async
    test('test listRepos', () async {
      // TODO
    });
  });
}
