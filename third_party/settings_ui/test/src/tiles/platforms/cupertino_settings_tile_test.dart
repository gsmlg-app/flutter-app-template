import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('CupertinoSettingsTile', () {
    testWidgets('renders on iOS platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('iOS Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('iOS Tile'), findsOneWidget);
    });

    testWidgets('renders on macOS platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.macOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('macOS Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('macOS Tile'), findsOneWidget);
    });

    testWidgets('uses CupertinoSwitch widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
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

      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });

    testWidgets('CupertinoSwitch reflects initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Switch'),
                      initialValue: true,
                      onToggle: (value) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final switchWidget =
          tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('navigation tile shows chevron', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.navigation(
                      title: const Text('Navigation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    });

    testWidgets('navigation tile shows value with chevron', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.navigation(
                      title: const Text('Language'),
                      value: const Text('English'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    });

    testWidgets('renders with leading icon', (tester) async {
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
                      leading: const Icon(CupertinoIcons.gear),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.gear), findsOneWidget);
    });

    testWidgets('renders description below section', (tester) async {
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
                      description: const Text('Footer description'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Footer description'), findsOneWidget);
    });
  });
}
