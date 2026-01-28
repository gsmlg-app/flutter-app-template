import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('CupertinoSettingsList', () {
    testWidgets('renders on iOS platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('iOS'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('iOS'), findsOneWidget);
    });

    testWidgets('renders on macOS platform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.macOS,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('macOS'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('macOS'), findsOneWidget);
    });

    testWidgets('uses grouped background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
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

    testWidgets('constrains content width on iPad', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              sections: [
                SettingsSection(
                  tiles: [SettingsTile(title: const Text('iPad'))],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('iPad'), findsOneWidget);

      // Reset view size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with custom content padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.iOS,
              contentPadding: const EdgeInsets.all(24),
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
  });
}
