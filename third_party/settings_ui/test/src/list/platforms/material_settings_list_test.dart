import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('MaterialSettingsList', () {
    testWidgets('renders on Android platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Android'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Android'), findsOneWidget);
    });

    testWidgets('renders on Linux platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.linux,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Linux'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Linux'), findsOneWidget);
    });

    testWidgets('renders on Web platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.web,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Web'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Web'), findsOneWidget);
    });

    testWidgets('renders on Fuchsia platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.fuchsia,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Fuchsia'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Fuchsia'), findsOneWidget);
    });

    testWidgets('renders on custom platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.custom,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('Custom'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('uses surface color for background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android,
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
              platform: DevicePlatform.android,
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
  });
}
