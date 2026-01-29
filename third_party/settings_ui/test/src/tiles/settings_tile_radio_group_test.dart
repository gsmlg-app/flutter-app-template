import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile.radioGroup', () {
    final testOptions = [
      const SettingsOption(value: 'en', label: 'English'),
      const SettingsOption(value: 'es', label: 'Spanish'),
      const SettingsOption(value: 'fr', label: 'French'),
    ];

    testWidgets('creates radio group tile with required properties', (tester) async {
      String? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.radioGroup(
                      title: const Text('Language'),
                      options: testOptions,
                      radioValue: 'en',
                      onRadioChanged: (value) => capturedValue = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('displays all options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.radioGroup(
                      title: const Text('Language'),
                      options: testOptions,
                      radioValue: 'en',
                      onRadioChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);
    });

    testWidgets('creates radio group tile with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.radioGroup(
                      title: const Text('Language'),
                      leading: const Icon(Icons.language),
                      options: testOptions,
                      onRadioChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('creates radio group tile with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.radioGroup(
                      title: const Text('Language'),
                      description: const Text('Select your preferred language'),
                      options: testOptions,
                      onRadioChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Select your preferred language'), findsOneWidget);
    });

    test('has correct tile type', () {
      final tile = SettingsTile.radioGroup(
        title: const Text('Test'),
        options: testOptions,
        onRadioChanged: (_) {},
      );

      expect(tile.tileType, SettingsTileType.radioGroupTile);
    });

    test('stores radio group properties correctly', () {
      void callback(String? value) {}

      final tile = SettingsTile.radioGroup(
        title: const Text('Test'),
        options: testOptions,
        radioValue: 'es',
        onRadioChanged: callback,
      );

      expect(tile.radioOptions, testOptions);
      expect(tile.radioValue, 'es');
      expect(tile.onRadioChanged, callback);
    });

    test('can have null selected value', () {
      final tile = SettingsTile.radioGroup(
        title: const Text('Test'),
        options: testOptions,
        radioValue: null,
        onRadioChanged: (_) {},
      );

      expect(tile.radioValue, null);
    });

    test('can be disabled', () {
      final tile = SettingsTile.radioGroup(
        title: const Text('Test'),
        options: testOptions,
        onRadioChanged: (_) {},
        enabled: false,
      );

      expect(tile.enabled, false);
    });

    testWidgets('options with icons render correctly', (tester) async {
      final optionsWithIcons = [
        const SettingsOption(
          value: 'en',
          label: 'English',
          icon: Icon(Icons.flag),
        ),
        const SettingsOption(
          value: 'es',
          label: 'Spanish',
          icon: Icon(Icons.flag_outlined),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.radioGroup(
                      title: const Text('Language'),
                      options: optionsWithIcons,
                      radioValue: 'en',
                      onRadioChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
    });
  });
}
