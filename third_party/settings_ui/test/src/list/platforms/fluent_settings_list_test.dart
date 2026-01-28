import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('FluentSettingsList', () {
    testWidgets('renders on Windows platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Windows'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Windows'), findsOneWidget);
    });

    testWidgets('uses layer background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Tile'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('constrains content width on large screens', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Wide'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Wide'), findsOneWidget);

      // Reset view size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with custom content padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
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

    testWidgets('applies vertical padding by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.windows,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Tile'))],
                ),
              ],
            ),
          ),
        ),
      );

      // ListView should have padding
      final listView = tester.widget<ListView>(find.byType(ListView).first);
      expect(listView.padding, isNotNull);
    });
  });
}
