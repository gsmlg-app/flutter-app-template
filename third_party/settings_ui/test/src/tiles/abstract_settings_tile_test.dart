import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTileType', () {
    test('enum contains all expected tile types', () {
      expect(SettingsTileType.values.length, 4);
      expect(SettingsTileType.values, contains(SettingsTileType.simpleTile));
      expect(SettingsTileType.values, contains(SettingsTileType.switchTile));
      expect(SettingsTileType.values, contains(SettingsTileType.navigationTile));
      expect(SettingsTileType.values, contains(SettingsTileType.checkTile));
    });
  });
}
