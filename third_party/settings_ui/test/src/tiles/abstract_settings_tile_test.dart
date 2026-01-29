import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTileType', () {
    test('enum contains all expected tile types', () {
      expect(SettingsTileType.values.length, 10);
      expect(SettingsTileType.values, contains(SettingsTileType.simpleTile));
      expect(SettingsTileType.values, contains(SettingsTileType.switchTile));
      expect(SettingsTileType.values, contains(SettingsTileType.navigationTile));
      expect(SettingsTileType.values, contains(SettingsTileType.checkTile));
      expect(SettingsTileType.values, contains(SettingsTileType.inputTile));
      expect(SettingsTileType.values, contains(SettingsTileType.sliderTile));
      expect(SettingsTileType.values, contains(SettingsTileType.selectTile));
      expect(SettingsTileType.values, contains(SettingsTileType.textareaTile));
      expect(SettingsTileType.values, contains(SettingsTileType.radioGroupTile));
      expect(SettingsTileType.values, contains(SettingsTileType.checkboxGroupTile));
    });
  });
}
