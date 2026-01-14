/// Abstract interface for secure secret storage.
///
/// This repository provides a platform-agnostic API for storing sensitive
/// user data such as API tokens, passwords, and encryption keys.
///
/// Implementations use platform-native secure storage:
/// - iOS/macOS: Keychain
/// - Android: EncryptedSharedPreferences / Keystore
/// - Linux: libsecret
/// - Windows: Windows Credential Manager
abstract class VaultRepository {
  /// Stores a secret value with the given key.
  ///
  /// If a value already exists for the key, it will be overwritten.
  Future<void> write({required String key, required String value});

  /// Retrieves a secret value by key.
  ///
  /// Returns `null` if no value exists for the given key.
  Future<String?> read({required String key});

  /// Deletes a secret by key.
  ///
  /// Does nothing if the key doesn't exist.
  Future<void> delete({required String key});

  /// Checks if a secret exists for the given key.
  Future<bool> containsKey({required String key});

  /// Deletes all secrets from the vault.
  Future<void> deleteAll();

  /// Returns all keys stored in the vault.
  Future<Map<String, String>> readAll();
}
