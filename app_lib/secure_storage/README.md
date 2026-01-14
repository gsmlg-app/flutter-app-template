# app_secure_storage

A secure storage package for Flutter applications that provides platform-native secure storage for sensitive user data such as API tokens, passwords, and encryption keys.

## Features

- Platform-native secure storage (Keychain, Keystore, libsecret, Credential Manager)
- Abstract repository interface for easy testing and mocking
- Optional namespace support to prevent key collisions
- Simple async API for CRUD operations

## Platform Support

| Platform | Storage Mechanism |
|----------|-------------------|
| iOS | Keychain Services |
| macOS | Keychain Services |
| Android | EncryptedSharedPreferences (AES) |
| Linux | libsecret |
| Windows | Windows Credential Manager |

## Setup

### 1. Add Dependency

The package is already included in the workspace. For other packages that need vault access, add to `pubspec.yaml`:

```yaml
dependencies:
  app_secure_storage: any
```

### 2. Provider Integration

The vault is already integrated into `MainProvider`. It's initialized in `lib/main.dart`:

```dart
import 'package:app_secure_storage/app_secure_storage.dart';

void main() async {
  // ...
  final vault = SecureStorageVaultRepository();

  runApp(
    MainProvider(
      sharedPrefs: sharedPrefs,
      database: database,
      vault: vault,
      child: MyApp(),
    ),
  );
}
```

## Platform Setup

### Android

**Minimum SDK Version**

Set `minSdkVersion` to at least 18 in `android/app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        minSdk = 23  // Recommended: 23+ for EncryptedSharedPreferences
    }
}
```

- API 18+: Basic support with AES encryption
- API 23+ (Android 6.0): Uses EncryptedSharedPreferences with AES-GCM
- API 28+ (Android 9.0): Required for enforced biometric authentication

**Disable Auto Backup (Required)**

To prevent `java.security.InvalidKeyException` errors after app restore, disable auto backup or exclude the secure storage SharedPreferences.

Option 1 - Disable backup entirely in `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    ...>
```

Option 2 - Exclude secure storage from backup by creating `android/app/src/main/res/xml/backup_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="sharedpref" path="FlutterSecureStorage"/>
</full-backup-content>
```

Then reference it in `AndroidManifest.xml`:

```xml
<application
    android:fullBackupContent="@xml/backup_rules"
    ...>
```

**Biometric Authentication (Optional)**

To use biometric authentication, add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<!-- For Android 6.0-8.1 compatibility -->
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS

**Keychain Entitlements (Required)**

Add keychain access groups to **both** `ios/Runner/DebugProfile.entitlements` and `ios/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array/>
</dict>
</plist>
```

> **Important**: Failure to add this entitlement will result in values appearing to be written successfully but never actually being written at all.

**Keychain Accessibility Options**

Configure when secrets can be accessed:

```dart
final storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);
final vault = SecureStorageVaultRepository(storage: storage);
```

Available accessibility options:
| Option | Description |
|--------|-------------|
| `passcode` | Requires device passcode to be set |
| `unlocked` | Only when device is unlocked |
| `first_unlock` | After first unlock since boot (recommended for background access) |
| `first_unlock_this_device` | Same as above, but not included in backups |

**App Groups / Keychain Sharing (Optional)**

To share secrets between apps or app extensions:

1. Add to entitlements:
```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.shared</string>
</array>
```

2. Configure storage:
```dart
final storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    groupId: 'com.yourcompany.shared',
    accountName: 'MyApp',
  ),
);
```

### macOS

**Keychain Entitlements (Required)**

Add keychain access groups to **both** `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array/>
</dict>
</plist>
```

> **Important**: Same as iOS - without this entitlement, writes will silently fail.

**App Groups (Optional)**

For sharing between apps, add to entitlements:

```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.shared</string>
</array>
```

### Linux

**Build Dependencies**

Install required libraries for compilation:

```bash
# Debian/Ubuntu
sudo apt-get install libsecret-1-dev libjsoncpp-dev

# Fedora
sudo dnf install libsecret-devel jsoncpp-devel

# Arch Linux
sudo pacman -S libsecret jsoncpp
```

**Runtime Dependencies**

For deployment, ensure these are installed:

```bash
# Debian/Ubuntu
sudo apt-get install libsecret-1-0 libjsoncpp1
```

**Keyring Service**

A keyring service must be running:
- **GNOME**: GNOME Keyring (usually pre-installed)
- **KDE**: KWallet
- **Other**: Install and configure `gnome-keyring`

**Snapcraft Configuration**

If building as a Snap, add to `snapcraft.yaml`:

```yaml
parts:
  your-app:
    build-packages:
      - libsecret-1-dev
      - libjsoncpp-dev
    stage-packages:
      - libsecret-1-0
      - libjsoncpp1
```

### Windows

**Build Requirements**

Install Visual Studio Build Tools with C++ components:

1. Download [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Select "Desktop development with C++"
3. In Optional components, ensure "C++ ATL for latest build tools" is selected

**Limitations**

Note: The Windows implementation has some limitations:
- `readAll()` and `deleteAll()` may not work as expected in some versions
- Consider using namespaced keys and individual delete operations

## Usage

### Access from BuildContext

```dart
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Get the vault repository
final vault = context.read<VaultRepository>();
```

### Store a Secret

```dart
await vault.write(key: 'api_token', value: 'your-secret-token');
```

### Read a Secret

```dart
final token = await vault.read(key: 'api_token');
if (token != null) {
  // Use the token
}
```

### Check if Key Exists

```dart
final exists = await vault.containsKey(key: 'api_token');
```

### Delete a Secret

```dart
await vault.delete(key: 'api_token');
```

### Delete All Secrets

```dart
await vault.deleteAll();
```

### Read All Secrets

```dart
final allSecrets = await vault.readAll();
// Returns Map<String, String>
```

## Namespaces

Use namespaces to organize secrets and prevent key collisions between features:

```dart
// Create namespaced vaults for different features
final authVault = SecureStorageVaultRepository(namespace: 'auth');
final apiVault = SecureStorageVaultRepository(namespace: 'api');

// Keys are automatically prefixed: 'auth_token', 'api_key'
await authVault.write(key: 'token', value: 'jwt-token');
await apiVault.write(key: 'key', value: 'api-key-123');

// deleteAll() only affects keys within the namespace
await authVault.deleteAll(); // Only deletes 'auth_*' keys
```

## Testing

The abstract `VaultRepository` interface makes testing easy:

```dart
class MockVaultRepository implements VaultRepository {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }
}
```

Use in tests:

```dart
void main() {
  testWidgets('stores user token', (tester) async {
    final mockVault = MockVaultRepository();

    await tester.pumpWidget(
      RepositoryProvider<VaultRepository>.value(
        value: mockVault,
        child: MyWidget(),
      ),
    );

    // Test your widget...
    expect(await mockVault.read(key: 'token'), equals('expected-value'));
  });
}
```

## Security Considerations

1. **Key Naming**: Use descriptive, consistent key names (e.g., `auth_access_token`, `api_refresh_token`).

2. **Error Handling**: Always handle potential errors when accessing secure storage:

```dart
try {
  final token = await vault.read(key: 'api_token');
  // Use token
} catch (e) {
  // Handle error (e.g., storage not available)
}
```

3. **Cleanup**: Delete secrets when they're no longer needed (e.g., on logout):

```dart
Future<void> logout() async {
  await vault.delete(key: 'access_token');
  await vault.delete(key: 'refresh_token');
  // Or use namespace and deleteAll()
}
```

## Demo

See the vault in action in the app's Showcase section:

**Showcase > Secure Vault** (`/showcase/vault`)

The demo allows you to:
- Store key-value secrets
- View stored secrets
- Copy values to clipboard
- Delete individual or all secrets

## API Reference

### VaultRepository (Abstract Interface)

| Method | Description |
|--------|-------------|
| `write({key, value})` | Store a secret |
| `read({key})` | Retrieve a secret (returns `null` if not found) |
| `delete({key})` | Remove a secret |
| `containsKey({key})` | Check if a key exists |
| `deleteAll()` | Remove all secrets |
| `readAll()` | Get all stored secrets as a Map |

### SecureStorageVaultRepository

| Constructor Parameter | Description |
|----------------------|-------------|
| `storage` | Optional custom `FlutterSecureStorage` instance |
| `namespace` | Optional prefix for all keys |
