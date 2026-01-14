import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'vault_repository.dart';

/// Implementation of [VaultRepository] using flutter_secure_storage.
///
/// This implementation provides secure storage using platform-native
/// mechanisms:
/// - iOS/macOS: Keychain Services
/// - Android: EncryptedSharedPreferences with AES encryption
/// - Linux: libsecret
/// - Windows: Windows Credential Manager
/// - Web: Uses encrypted local storage (less secure than native platforms)
class SecureStorageVaultRepository implements VaultRepository {
  SecureStorageVaultRepository({
    FlutterSecureStorage? storage,
    this.namespace,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Optional namespace prefix for keys to avoid collisions.
  final String? namespace;

  /// Returns the namespaced key if a namespace is set.
  String _prefixedKey(String key) {
    if (namespace != null && namespace!.isNotEmpty) {
      return '${namespace}_$key';
    }
    return key;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: _prefixedKey(key), value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage.read(key: _prefixedKey(key));
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: _prefixedKey(key));
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: _prefixedKey(key));
  }

  @override
  Future<void> deleteAll() async {
    if (namespace != null && namespace!.isNotEmpty) {
      // Only delete keys with our namespace prefix
      final all = await _storage.readAll();
      for (final key in all.keys) {
        if (key.startsWith('${namespace}_')) {
          await _storage.delete(key: key);
        }
      }
    } else {
      await _storage.deleteAll();
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    final all = await _storage.readAll();
    if (namespace != null && namespace!.isNotEmpty) {
      // Only return keys with our namespace prefix, stripped of prefix
      final prefix = '${namespace}_';
      return Map.fromEntries(
        all.entries
            .where((e) => e.key.startsWith(prefix))
            .map((e) => MapEntry(e.key.substring(prefix.length), e.value)),
      );
    }
    return all;
  }
}
