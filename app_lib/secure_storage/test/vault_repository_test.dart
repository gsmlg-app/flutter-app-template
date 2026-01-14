import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory implementation of VaultRepository for testing.
class InMemoryVaultRepository implements VaultRepository {
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

void main() {
  group('VaultRepository', () {
    late VaultRepository vault;

    setUp(() {
      vault = InMemoryVaultRepository();
    });

    test('write and read a secret', () async {
      await vault.write(key: 'api_token', value: 'secret123');
      final result = await vault.read(key: 'api_token');
      expect(result, equals('secret123'));
    });

    test('read returns null for non-existent key', () async {
      final result = await vault.read(key: 'non_existent');
      expect(result, isNull);
    });

    test('write overwrites existing value', () async {
      await vault.write(key: 'token', value: 'first');
      await vault.write(key: 'token', value: 'second');
      final result = await vault.read(key: 'token');
      expect(result, equals('second'));
    });

    test('delete removes a secret', () async {
      await vault.write(key: 'to_delete', value: 'value');
      await vault.delete(key: 'to_delete');
      final result = await vault.read(key: 'to_delete');
      expect(result, isNull);
    });

    test('delete does nothing for non-existent key', () async {
      // Should not throw
      await vault.delete(key: 'non_existent');
    });

    test('containsKey returns true for existing key', () async {
      await vault.write(key: 'exists', value: 'value');
      final result = await vault.containsKey(key: 'exists');
      expect(result, isTrue);
    });

    test('containsKey returns false for non-existent key', () async {
      final result = await vault.containsKey(key: 'non_existent');
      expect(result, isFalse);
    });

    test('deleteAll clears all secrets', () async {
      await vault.write(key: 'key1', value: 'value1');
      await vault.write(key: 'key2', value: 'value2');
      await vault.deleteAll();
      expect(await vault.containsKey(key: 'key1'), isFalse);
      expect(await vault.containsKey(key: 'key2'), isFalse);
    });

    test('readAll returns all stored secrets', () async {
      await vault.write(key: 'a', value: '1');
      await vault.write(key: 'b', value: '2');
      final all = await vault.readAll();
      expect(all, equals({'a': '1', 'b': '2'}));
    });

    test('readAll returns empty map when no secrets', () async {
      final all = await vault.readAll();
      expect(all, isEmpty);
    });
  });
}
