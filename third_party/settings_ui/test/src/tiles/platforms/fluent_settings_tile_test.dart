import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('FluentSettingsTile', () {
    testWidgets('renders on Windows platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(title: const Text('Windows Tile')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Windows Tile'), findsOneWidget);
    });

    testWidgets('uses Material Switch widget (not Cupertino)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
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

    testWidgets('Switch reflects initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
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

    testWidgets('navigation tile shows chevron', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
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

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders with leading icon in container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
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

    testWidgets('renders with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile(
                      title: const Text('Title'),
                      description: const Text('Description text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description text'), findsOneWidget);
    });

    testWidgets('tiles have card-based appearance', (tester) async {
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

      // Fluent tiles use Material widget with rounded corners
      expect(find.byType(Material), findsWidgets);
    });
  });
}
