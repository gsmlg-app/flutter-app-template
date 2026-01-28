import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile', () {
    group('default constructor (simple tile)', () {
      testWidgets('renders with title only', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile(title: const Text('Simple Tile')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Simple Tile'), findsOneWidget);
      });

      testWidgets('renders with description', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile(
                        title: const Text('Tile'),
                        description: const Text('Description text'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Description text'), findsOneWidget);
      });

      testWidgets('renders with leading icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile(
                        title: const Text('Tile'),
                        leading: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('renders with trailing widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile(
                        title: const Text('Tile'),
                        trailing: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile(
                        title: const Text('Tappable'),
                        onPressed: (context) => tapped = true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tappable'));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('does not respond when disabled', (tester) async {
        var tapped = false;

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
                        onPressed: (context) => tapped = true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Disabled'), warnIfMissed: false);
        await tester.pump();

        expect(tapped, isFalse);
      });
    });

    group('navigation constructor', () {
      testWidgets('renders navigation tile', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
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

        expect(find.text('Navigation'), findsOneWidget);
      });

      testWidgets('renders with value widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
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

        expect(find.text('Language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
      });
    });

    group('switchTile constructor', () {
      testWidgets('renders switch tile', (tester) async {
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

        expect(find.text('Switch'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('switch reflects initial value true', (tester) async {
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

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);
      });

      testWidgets('switch reflects initial value false', (tester) async {
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

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isFalse);
      });

      testWidgets('calls onToggle when switch is tapped', (tester) async {
        bool? toggledValue;

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
                        onToggle: (value) => toggledValue = value,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byType(Switch));
        await tester.pump();

        expect(toggledValue, isTrue);
      });

      testWidgets('renders with description', (tester) async {
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
                        description: const Text('Toggle this setting'),
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

        expect(find.text('Toggle this setting'), findsOneWidget);
      });
    });

    group('checkTile constructor', () {
      testWidgets('renders check tile with checked state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile.checkTile(
                        title: const Text('Checked'),
                        checked: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Checked'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('renders check tile with unchecked state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile.checkTile(
                        title: const Text('Unchecked'),
                        checked: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Unchecked'), findsOneWidget);
        // Icon exists but is transparent
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsList(
                platform: DevicePlatform.android,
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile.checkTile(
                        title: const Text('Check'),
                        checked: false,
                        onPressed: (context) => tapped = true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check'));
        await tester.pump();

        expect(tapped, isTrue);
      });
    });
  });
}
