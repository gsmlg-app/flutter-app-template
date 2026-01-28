import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  group('SettingsThemeData', () {
    group('withColorScheme', () {
      test('creates Material theme for Android', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.android,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
        expect(theme.titleTextColor, isNotNull);
      });

      test('creates Material theme for Linux', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.linux,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
      });

      test('creates Material theme for Web', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.web,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
      });

      test('creates Material theme for Fuchsia', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.fuchsia,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
      });

      test('creates Material theme for custom', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.custom,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
      });

      test('creates Cupertino theme for iOS', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.iOS,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
        expect(theme.settingsSectionBackground, isNotNull);
      });

      test('creates Cupertino theme for macOS', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.macOS,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
        expect(theme.settingsSectionBackground, isNotNull);
      });

      test('creates Fluent theme for Windows', () {
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = SettingsThemeData.withColorScheme(
          colorScheme,
          DevicePlatform.windows,
        );

        expect(theme, isNotNull);
        expect(theme.settingsListBackground, isNotNull);
        expect(theme.settingsSectionBackground, isNotNull);
      });
    });

    group('copyWith', () {
      test('creates new instance with overridden values', () {
        final original = SettingsThemeData(
          settingsListBackground: Colors.white,
          titleTextColor: Colors.black,
        );

        final copied = original.copyWith(
          titleTextColor: Colors.red,
        );

        expect(copied.settingsListBackground, Colors.white);
        expect(copied.titleTextColor, Colors.red);
      });

      test('preserves original values when not overridden', () {
        final original = SettingsThemeData(
          settingsListBackground: Colors.white,
          titleTextColor: Colors.black,
          leadingIconsColor: Colors.blue,
        );

        final copied = original.copyWith(
          titleTextColor: Colors.red,
        );

        expect(copied.settingsListBackground, Colors.white);
        expect(copied.leadingIconsColor, Colors.blue);
      });
    });

    group('merge', () {
      test('combines two theme data objects', () {
        final base = SettingsThemeData(
          settingsListBackground: Colors.white,
          titleTextColor: Colors.black,
        );

        final overlay = SettingsThemeData(
          titleTextColor: Colors.blue,
          leadingIconsColor: Colors.green,
        );

        final merged = base.merge(theme: overlay);

        expect(merged.settingsListBackground, Colors.white);
        expect(merged.titleTextColor, Colors.blue);
        expect(merged.leadingIconsColor, Colors.green);
      });

      test('returns same instance when merging with null', () {
        final original = SettingsThemeData(
          settingsListBackground: Colors.white,
        );

        final merged = original.merge(theme: null);

        expect(merged, original);
      });
    });
  });

  group('SettingsTheme InheritedWidget', () {
    testWidgets('provides theme data to descendants', (tester) async {
      final themeData = SettingsThemeData(
        settingsListBackground: Colors.red,
      );

      late SettingsTheme capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsTheme(
            themeData: themeData,
            platform: DevicePlatform.android,
            child: Builder(
              builder: (context) {
                capturedTheme = SettingsTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedTheme.themeData.settingsListBackground, Colors.red);
      expect(capturedTheme.platform, DevicePlatform.android);
    });

    testWidgets('maybeOf returns null when no theme in context', (tester) async {
      SettingsTheme? capturedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedTheme = SettingsTheme.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedTheme, isNull);
    });
  });
}
