import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile.checkboxGroup', () {
    final testOptions = [
      const SettingsOption(value: 'email', label: 'Email'),
      const SettingsOption(value: 'push', label: 'Push Notifications'),
      const SettingsOption(value: 'sms', label: 'SMS'),
    ];

    testWidgets('creates checkbox group tile with required properties', (tester) async {
      Set<String>? capturedValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.checkboxGroup(
                      title: const Text('Notifications'),
                      options: testOptions,
                      checkboxValues: {'email'},
                      onCheckboxChanged: (values) => capturedValues = values,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
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
                    SettingsTile.checkboxGroup(
                      title: const Text('Notifications'),
                      options: testOptions,
                      checkboxValues: {'email', 'push'},
                      onCheckboxChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
    });

    testWidgets('creates checkbox group tile with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.checkboxGroup(
                      title: const Text('Notifications'),
                      leading: const Icon(Icons.notifications),
                      options: testOptions,
                      checkboxValues: {},
                      onCheckboxChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('creates checkbox group tile with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.checkboxGroup(
                      title: const Text('Notifications'),
                      description: const Text('Choose how you want to be notified'),
                      options: testOptions,
                      checkboxValues: {},
                      onCheckboxChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Choose how you want to be notified'), findsOneWidget);
    });

    test('has correct tile type', () {
      final tile = SettingsTile.checkboxGroup(
        title: const Text('Test'),
        options: testOptions,
        checkboxValues: {},
        onCheckboxChanged: (_) {},
      );

      expect(tile.tileType, SettingsTileType.checkboxGroupTile);
    });

    test('stores checkbox group properties correctly', () {
      void callback(Set<String> values) {}

      final tile = SettingsTile.checkboxGroup(
        title: const Text('Test'),
        options: testOptions,
        checkboxValues: {'email', 'sms'},
        onCheckboxChanged: callback,
      );

      expect(tile.checkboxOptions, testOptions);
      expect(tile.checkboxValues, {'email', 'sms'});
      expect(tile.onCheckboxChanged, callback);
    });

    test('can have empty selected values', () {
      final tile = SettingsTile.checkboxGroup(
        title: const Text('Test'),
        options: testOptions,
        checkboxValues: {},
        onCheckboxChanged: (_) {},
      );

      expect(tile.checkboxValues, isEmpty);
    });

    test('can have all options selected', () {
      final tile = SettingsTile.checkboxGroup(
        title: const Text('Test'),
        options: testOptions,
        checkboxValues: {'email', 'push', 'sms'},
        onCheckboxChanged: (_) {},
      );

      expect(tile.checkboxValues, {'email', 'push', 'sms'});
    });

    test('can be disabled', () {
      final tile = SettingsTile.checkboxGroup(
        title: const Text('Test'),
        options: testOptions,
        checkboxValues: {},
        onCheckboxChanged: (_) {},
        enabled: false,
      );

      expect(tile.enabled, false);
    });

    testWidgets('options with icons render correctly', (tester) async {
      final optionsWithIcons = [
        const SettingsOption(
          value: 'email',
          label: 'Email',
          icon: Icon(Icons.email),
        ),
        const SettingsOption(
          value: 'push',
          label: 'Push',
          icon: Icon(Icons.notifications_active),
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
                    SettingsTile.checkboxGroup(
                      title: const Text('Notifications'),
                      options: optionsWithIcons,
                      checkboxValues: {'email'},
                      onCheckboxChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget);
    });
  });
}
