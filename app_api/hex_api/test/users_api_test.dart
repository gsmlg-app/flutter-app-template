import 'package:test/test.dart';
import 'package:hex_api/hex_api.dart';

/// tests for UsersApi
void main() {
  final instance = HexApi().getUsersApi();

  group(UsersApi, () {
    // Create a User
    //
    // Creates a new user. A confirmation email with an activation link is sent to the provided email address.  The account must be activated before it can be used.  Clients must display a link to the Hex Terms of Service.
    //
    //Future<User> createUser(UserCreate userCreate) async
    test('test createUser', () async {
      // TODO
    });

    // Fetch Currently Authenticated User
    //
    //Future<UserWithOrgs> getCurrentUser() async
    test('test getCurrentUser', () async {
      // TODO
    });

    // Fetch a User
    //
    //Future<User> getUser(String usernameOrEmail) async
    test('test getUser', () async {
      // TODO
    });

    // Reset User Password
    //
    // Initiates the password reset process. An email with a reset link will be sent to the user's primary email address.
    //
    //Future resetUserPassword(String usernameOrEmail) async
    test('test resetUserPassword', () async {
      // TODO
    });
  });
}
