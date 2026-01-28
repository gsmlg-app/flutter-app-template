import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('CupertinoSettingsSection', () {
    testWidgets('renders on iOS platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  title: const Text('iOS Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('iOS Section'), findsOneWidget);
    });

    testWidgets('renders on macOS platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.macOS,
              sections: [
                SettingsSection(
                  title: const Text('macOS Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('macOS Section'), findsOneWidget);
    });

    testWidgets('has inset grouped style with rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // ClipRRect is used for rounded corners
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('renders multiple tiles with dividers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Tile 1')),
                    SettingsTile(title: const Text('Tile 2')),
                    SettingsTile(title: const Text('Tile 3')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tile 1'), findsOneWidget);
      expect(find.text('Tile 2'), findsOneWidget);
      expect(find.text('Tile 3'), findsOneWidget);
    });

    testWidgets('renders section footer (description)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(
                      title: const Text('Tile'),
                      description: const Text('Section footer text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Section footer text'), findsOneWidget);
    });

    testWidgets('renders multiple sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  title: const Text('GENERAL'),
                  tiles: [SettingsTile(title: const Text('General Tile'))],
                ),
                SettingsSection(
                  title: const Text('PRIVACY'),
                  tiles: [SettingsTile(title: const Text('Privacy Tile'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('PRIVACY'), findsOneWidget);
    });
  });
}
