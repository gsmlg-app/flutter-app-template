import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('DevicePlatform', () {
    test('enum contains all expected platforms', () {
      expect(DevicePlatform.values.length, 8);
      expect(DevicePlatform.values, contains(DevicePlatform.android));
      expect(DevicePlatform.values, contains(DevicePlatform.iOS));
      expect(DevicePlatform.values, contains(DevicePlatform.macOS));
      expect(DevicePlatform.values, contains(DevicePlatform.windows));
      expect(DevicePlatform.values, contains(DevicePlatform.linux));
      expect(DevicePlatform.values, contains(DevicePlatform.web));
      expect(DevicePlatform.values, contains(DevicePlatform.fuchsia));
      expect(DevicePlatform.values, contains(DevicePlatform.custom));
    });

    test('Material design platforms', () {
      // These platforms should use Material Design
      const materialPlatforms = [
        DevicePlatform.android,
        DevicePlatform.linux,
        DevicePlatform.web,
        DevicePlatform.fuchsia,
        DevicePlatform.custom,
      ];

      for (final platform in materialPlatforms) {
        expect(DevicePlatform.values, contains(platform));
      }
    });

    test('Cupertino design platforms', () {
      // These platforms should use Cupertino Design
      const cupertinoPlatforms = [
        DevicePlatform.iOS,
        DevicePlatform.macOS,
      ];

      for (final platform in cupertinoPlatforms) {
        expect(DevicePlatform.values, contains(platform));
      }
    });

    test('Fluent design platforms', () {
      // Windows should use Fluent Design
      expect(DevicePlatform.values, contains(DevicePlatform.windows));
    });
  });
}
