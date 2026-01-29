import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile.input', () {
    testWidgets('creates input tile with required properties', (tester) async {
      String? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.input(
                      title: const Text('Username'),
                      inputValue: 'initial',
                      onInputChanged: (value) => capturedValue = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
    });

    testWidgets('creates input tile with hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.input(
                      title: const Text('Email'),
                      inputHint: 'Enter your email',
                      onInputChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('creates input tile with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.input(
                      title: const Text('Search'),
                      leading: const Icon(Icons.search),
                      onInputChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('creates input tile with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.input(
                      title: const Text('API Key'),
                      description: const Text('Enter your API key'),
                      onInputChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('API Key'), findsOneWidget);
      expect(find.text('Enter your API key'), findsOneWidget);
    });

    test('has correct tile type', () {
      final tile = SettingsTile.input(
        title: const Text('Test'),
        onInputChanged: (_) {},
      );

      expect(tile.tileType, SettingsTileType.inputTile);
    });

    test('stores input properties correctly', () {
      void callback(String value) {}

      final tile = SettingsTile.input(
        title: const Text('Test'),
        inputValue: 'test value',
        onInputChanged: callback,
        inputHint: 'hint text',
        inputKeyboardType: TextInputType.emailAddress,
        inputMaxLength: 50,
      );

      expect(tile.inputValue, 'test value');
      expect(tile.onInputChanged, callback);
      expect(tile.inputHint, 'hint text');
      expect(tile.inputKeyboardType, TextInputType.emailAddress);
      expect(tile.inputMaxLength, 50);
    });

    test('can be disabled', () {
      final tile = SettingsTile.input(
        title: const Text('Test'),
        onInputChanged: (_) {},
        enabled: false,
      );

      expect(tile.enabled, false);
    });
  });
}
