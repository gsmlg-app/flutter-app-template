import 'package:flutter_test/flutter_test.dart';
import 'package:app_client_info/app_client_info.dart';
import 'package:app_client_info_platform_interface/app_client_info_platform_interface.dart';

// Mock platform implementation for testing
class MockClientInfoPlatform extends ClientInfoPlatform {
  @override
  Future<Map<String, dynamic>> getData() async {
    return {
      'platform': 'test',
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': {
        'test_key': 'test_value',
      },
    };
  }

  @override
  Future<void> refresh() async {
    // Mock refresh
  }
}

void main() {
  group('ClientInfo', () {
    late ClientInfo clientInfo;

    setUp(() {
      // Set mock platform for testing
      ClientInfo.setMockPlatform(MockClientInfoPlatform());
      clientInfo = ClientInfo.instance;
    });

    tearDown(() {
      ClientInfo.reset();
    });

    test('instance returns singleton', () {
      final instance1 = ClientInfo.instance;
      final instance2 = ClientInfo.instance;
      expect(instance1, same(instance2));
    });

    test('getData returns ClientInfoData', () async {
      final data = await clientInfo.getData();

      expect(data, isA<ClientInfoData>());
      expect(data.platform, equals('test'));
      expect(data.timestamp, isA<DateTime>());
      expect(data.additionalData, isNotEmpty);
      expect(data.additionalData['test_key'], equals('test_value'));
    });

    test('refresh calls platform refresh', () async {
      await expectLater(
        clientInfo.refresh(),
        completes,
      );
    });

    test('getData returns different timestamps on multiple calls', () async {
      final data1 = await clientInfo.getData();
      await Future.delayed(const Duration(milliseconds: 10));

      // Set new mock platform to simulate fresh data
      ClientInfo.setMockPlatform(MockClientInfoPlatform());
      final data2 = await clientInfo.getData();

      expect(data1.platform, equals(data2.platform));
    });
  });

  group('ClientInfoData', () {
    test('fromMap creates valid ClientInfoData', () {
      final map = {
        'platform': 'android',
        'timestamp': '2024-01-01T00:00:00.000Z',
        'additionalData': {
          'key': 'value',
        },
      };

      final data = ClientInfoData.fromMap(map);

      expect(data.platform, equals('android'));
      expect(data.timestamp, isA<DateTime>());
      expect(data.additionalData['key'], equals('value'));
    });

    test('toMap converts ClientInfoData to map', () {
      final data = ClientInfoData(
        platform: 'ios',
        timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
        additionalData: const {'test': 'data'},
      );

      final map = data.toMap();

      expect(map['platform'], equals('ios'));
      expect(map['timestamp'], isA<String>());
      expect(map['additionalData'], equals({'test': 'data'}));
    });

    test('equality works correctly', () {
      final timestamp = DateTime.now();
      final data1 = ClientInfoData(
        platform: 'test',
        timestamp: timestamp,
        additionalData: const {},
      );
      final data2 = ClientInfoData(
        platform: 'test',
        timestamp: timestamp,
        additionalData: const {},
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('toString returns formatted string', () {
      final data = ClientInfoData(
        platform: 'test',
        timestamp: DateTime.now(),
        additionalData: const {'key': 'value'},
      );

      final string = data.toString();

      expect(string, contains('ClientInfoData'));
      expect(string, contains('platform: test'));
    });
  });
}
