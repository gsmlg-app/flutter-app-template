import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('MaterialSettingsTile', () {
    testWidgets('renders on Android platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Material Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Material Tile'), findsOneWidget);
      // Material tiles use InkWell for tap feedback
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('renders on Linux platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.linux,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Linux Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Linux Tile'), findsOneWidget);
    });

    testWidgets('renders on Web platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.web,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Web Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Web Tile'), findsOneWidget);
    });

    testWidgets('renders on Fuchsia platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.fuchsia,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Fuchsia Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Fuchsia Tile'), findsOneWidget);
    });

    testWidgets('uses Material Switch widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Switch'),
                      initialValue: false,
                      onToggle: (value) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('respects two-line height with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(
                      title: const Text('Title'),
                      description: const Text('Description'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });
  });
}
