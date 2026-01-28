/// Integration tests for settings_ui package.
///
/// This file contains high-level integration tests. For unit tests,
/// see the individual test files in the src/ directory that mirror
/// the lib/src/ structure.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('settings_ui integration', () {
    testWidgets('complete settings screen with all tile types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  title: const Text('Account'),
                  tiles: [
                    SettingsTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile'),
                      description: const Text('View and edit profile'),
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      value: const Text('English'),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('Preferences'),
                  tiles: [
                    SettingsTile.switchTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      initialValue: false,
                      onToggle: (value) {},
                    ),
                    SettingsTile.switchTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      description: const Text('Receive push notifications'),
                      initialValue: true,
                      onToggle: (value) {},
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('Theme'),
                  tiles: [
                    SettingsTile.checkTile(
                      title: const Text('System Default'),
                      checked: true,
                    ),
                    SettingsTile.checkTile(
                      title: const Text('Light'),
                      checked: false,
                    ),
                    SettingsTile.checkTile(
                      title: const Text('Dark'),
                      checked: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all sections rendered
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Verify all tiles rendered
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Verify switches exist
      expect(find.byType(Switch), findsNWidgets(2));

      // Verify check icons exist
      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });

    testWidgets('all platforms render without errors', (tester) async {
      for (final platform in DevicePlatform.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: platform,
                sections: [
                  SettingsSection(
                    title: Text('$platform Section'),
                    tiles: [
                      SettingsTile(title: Text('$platform Tile')),
                      SettingsTile.navigation(title: const Text('Nav')),
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

        expect(find.text('$platform Section'), findsOneWidget);
        expect(find.text('$platform Tile'), findsOneWidget);
      }
    });

    testWidgets('iOS uses CupertinoSwitch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('iOS Switch'),
                      initialValue: true,
                      onToggle: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('Android uses Material Switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Android Switch'),
                      initialValue: true,
                      onToggle: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsNothing);
    });

    testWidgets('Windows uses Material Switch (Fluent style)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Windows Switch'),
                      initialValue: true,
                      onToggle: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsNothing);
    });

    testWidgets('disabled tiles do not respond to taps', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(
                      title: const Text('Disabled'),
                      enabled: false,
                      onPressed: (_) => tapCount++,
                    ),
                    SettingsTile(
                      title: const Text('Enabled'),
                      enabled: true,
                      onPressed: (_) => tapCount++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // Tap disabled tile
      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.pump();
      expect(tapCount, 0);

      // Tap enabled tile
      await tester.tap(find.text('Enabled'));
      await tester.pump();
      expect(tapCount, 1);
    });
  });
}
