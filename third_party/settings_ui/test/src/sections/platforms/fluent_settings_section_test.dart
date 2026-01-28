import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('FluentSettingsSection', () {
    testWidgets('renders on Windows platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  title: const Text('Windows Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Windows Section'), findsOneWidget);
    });

    testWidgets('renders tiles with spacing between them', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Tile 1')),
                    SettingsTile(title: const Text('Tile 2')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tile 1'), findsOneWidget);
      expect(find.text('Tile 2'), findsOneWidget);
      // SizedBox is used for spacing between cards
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('section without title renders tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Card Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Card Tile'), findsOneWidget);
    });

    testWidgets('renders multiple sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  title: const Text('System'),
                  tiles: [SettingsTile(title: const Text('Display'))],
                ),
                SettingsSection(
                  title: const Text('Personalization'),
                  tiles: [SettingsTile(title: const Text('Themes'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Personalization'), findsOneWidget);
      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Themes'), findsOneWidget);
    });
  });
}
