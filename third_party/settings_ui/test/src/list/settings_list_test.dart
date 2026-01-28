import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsList', () {
    testWidgets('renders with empty sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsList(sections: []),
          ),
        ),
      );

      expect(find.byType(SettingsList), findsOneWidget);
    });

    testWidgets('renders with sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Section'),
                  tiles: [
                    SettingsTile(title: const Text('Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Section'), findsOneWidget);
      expect(find.text('Tile'), findsOneWidget);
    });

    testWidgets('respects platform parameter for Material', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Material'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Material'), findsOneWidget);
    });

    testWidgets('respects platform parameter for Cupertino', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Cupertino'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cupertino'), findsOneWidget);
    });

    testWidgets('respects platform parameter for Fluent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Fluent'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Fluent'), findsOneWidget);
    });

    testWidgets('respects shrinkWrap property', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SettingsList(
                  shrinkWrap: true,
                  sections: [
                    SettingsSection(
                      tiles: [SettingsTile(title: const Text('Shrink'))],
                    ),
                  ],
                ),
                const Text('After List'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Shrink'), findsOneWidget);
      expect(find.text('After List'), findsOneWidget);
    });

    testWidgets('respects contentPadding property', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              contentPadding: const EdgeInsets.all(32),
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Padded'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('renders multiple sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Section 1'),
                  tiles: [SettingsTile(title: const Text('Tile 1'))],
                ),
                SettingsSection(
                  title: const Text('Section 2'),
                  tiles: [SettingsTile(title: const Text('Tile 2'))],
                ),
                SettingsSection(
                  title: const Text('Section 3'),
                  tiles: [SettingsTile(title: const Text('Tile 3'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
      expect(find.text('Section 3'), findsOneWidget);
    });
  });
}
