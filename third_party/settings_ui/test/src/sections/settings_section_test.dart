import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsSection', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  title: const Text('Section Title'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('renders without title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Tile Without Section Title')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tile Without Section Title'), findsOneWidget);
    });

    testWidgets('renders multiple tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
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

    testWidgets('renders with custom margin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  margin: const EdgeInsetsDirectional.all(20),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tile'), findsOneWidget);
    });

    testWidgets('renders mixed tile types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  title: const Text('Mixed'),
                  tiles: [
                    SettingsTile(title: const Text('Simple')),
                    SettingsTile.navigation(title: const Text('Navigation')),
                    SettingsTile.switchTile(
                      title: const Text('Switch'),
                      initialValue: false,
                      onToggle: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Simple'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);
    });
  });
}
