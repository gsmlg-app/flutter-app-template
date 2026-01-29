import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile.select', () {
    final testOptions = [
      const SettingsOption(value: 'light', label: 'Light'),
      const SettingsOption(value: 'dark', label: 'Dark'),
      const SettingsOption(value: 'system', label: 'System'),
    ];

    testWidgets('creates select tile with required properties', (tester) async {
      String? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.select(
                      title: const Text('Theme'),
                      options: testOptions,
                      selectValue: 'light',
                      onSelectChanged: (value) => capturedValue = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('displays current selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.select(
                      title: const Text('Theme'),
                      options: testOptions,
                      selectValue: 'dark',
                      onSelectChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('creates select tile with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.select(
                      title: const Text('Theme'),
                      leading: const Icon(Icons.color_lens),
                      options: testOptions,
                      onSelectChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.color_lens), findsOneWidget);
    });

    testWidgets('creates select tile with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.select(
                      title: const Text('Language'),
                      description: const Text('Choose your preferred language'),
                      options: testOptions,
                      onSelectChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Choose your preferred language'), findsOneWidget);
    });

    test('has correct tile type', () {
      final tile = SettingsTile.select(
        title: const Text('Test'),
        options: testOptions,
        onSelectChanged: (_) {},
      );

      expect(tile.tileType, SettingsTileType.selectTile);
    });

    test('stores select properties correctly', () {
      void callback(String? value) {}

      final tile = SettingsTile.select(
        title: const Text('Test'),
        options: testOptions,
        selectValue: 'dark',
        onSelectChanged: callback,
      );

      expect(tile.selectOptions, testOptions);
      expect(tile.selectValue, 'dark');
      expect(tile.onSelectChanged, callback);
    });

    test('can be disabled', () {
      final tile = SettingsTile.select(
        title: const Text('Test'),
        options: testOptions,
        onSelectChanged: (_) {},
        enabled: false,
      );

      expect(tile.enabled, false);
    });
  });

  group('SettingsOption', () {
    test('creates option with required properties', () {
      const option = SettingsOption(
        value: 'test_value',
        label: 'Test Label',
      );

      expect(option.value, 'test_value');
      expect(option.label, 'Test Label');
      expect(option.icon, null);
    });

    test('creates option with icon', () {
      const option = SettingsOption(
        value: 'with_icon',
        label: 'With Icon',
        icon: Icon(Icons.star),
      );

      expect(option.value, 'with_icon');
      expect(option.label, 'With Icon');
      expect(option.icon, isA<Icon>());
    });

    test('supports equality via const constructor', () {
      const option1 = SettingsOption(value: 'a', label: 'A');
      const option2 = SettingsOption(value: 'a', label: 'A');

      expect(identical(option1, option2), true);
    });
  });
}
