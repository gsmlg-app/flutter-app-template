import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsTile.slider', () {
    testWidgets('creates slider tile with required properties', (tester) async {
      double? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              platform: DevicePlatform.android, // Force Material design
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.slider(
                      title: const Text('Volume'),
                      sliderValue: 0.5,
                      onSliderChanged: (value) => capturedValue = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('creates slider tile with custom range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.slider(
                      title: const Text('Brightness'),
                      sliderValue: 50,
                      sliderMin: 0,
                      sliderMax: 100,
                      onSliderChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Brightness'), findsOneWidget);
    });

    testWidgets('creates slider tile with divisions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.slider(
                      title: const Text('Steps'),
                      sliderValue: 5,
                      sliderMin: 0,
                      sliderMax: 10,
                      sliderDivisions: 10,
                      onSliderChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Steps'), findsOneWidget);
    });

    testWidgets('creates slider tile with leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.slider(
                      title: const Text('Volume'),
                      sliderValue: 0.5,
                      leading: const Icon(Icons.volume_up),
                      onSliderChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('creates slider tile with description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Test Section'),
                  tiles: [
                    SettingsTile.slider(
                      title: const Text('Opacity'),
                      description: const Text('Adjust transparency'),
                      sliderValue: 0.8,
                      onSliderChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Opacity'), findsOneWidget);
      expect(find.text('Adjust transparency'), findsOneWidget);
    });

    test('has correct tile type', () {
      final tile = SettingsTile.slider(
        title: const Text('Test'),
        sliderValue: 0.5,
        onSliderChanged: (_) {},
      );

      expect(tile.tileType, SettingsTileType.sliderTile);
    });

    test('stores slider properties correctly', () {
      void callback(double value) {}

      final tile = SettingsTile.slider(
        title: const Text('Test'),
        sliderValue: 0.7,
        onSliderChanged: callback,
        sliderMin: 0.1,
        sliderMax: 0.9,
        sliderDivisions: 8,
      );

      expect(tile.sliderValue, 0.7);
      expect(tile.onSliderChanged, callback);
      expect(tile.sliderMin, 0.1);
      expect(tile.sliderMax, 0.9);
      expect(tile.sliderDivisions, 8);
    });

    test('has default min and max values', () {
      final tile = SettingsTile.slider(
        title: const Text('Test'),
        sliderValue: 0.5,
        onSliderChanged: (_) {},
      );

      expect(tile.sliderMin, 0.0);
      expect(tile.sliderMax, 1.0);
    });

    test('can be disabled', () {
      final tile = SettingsTile.slider(
        title: const Text('Test'),
        sliderValue: 0.5,
        onSliderChanged: (_) {},
        enabled: false,
      );

      expect(tile.enabled, false);
    });
  });
}
