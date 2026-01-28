import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('MaterialSettingsSection', () {
    testWidgets('renders on Android platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  title: const Text('Android Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Android Section'), findsOneWidget);
    });

    testWidgets('renders on Linux platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.linux,
              sections: [
                SettingsSection(
                  title: const Text('Linux Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Linux Section'), findsOneWidget);
    });

    testWidgets('renders on Web platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.web,
              sections: [
                SettingsSection(
                  title: const Text('Web Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Web Section'), findsOneWidget);
    });

    testWidgets('section without title renders tiles directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Direct Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Direct Tile'), findsOneWidget);
    });

    testWidgets('renders multiple sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  title: const Text('Section 1'),
                  tiles: [SettingsTile(title: const Text('Tile 1'))],
                ),
                SettingsSection(
                  title: const Text('Section 2'),
                  tiles: [SettingsTile(title: const Text('Tile 2'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
    });
  });
}
