import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/showcase/pelican_bicycle_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/widgets/pelican_bicycle_painter.dart';
import 'package:flutter_app_template/screens/showcase/widgets/pelican_bicycle_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PelicanBicycleWidget', () {
    testWidgets('renders CustomPaint with pelican bicycle painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PelicanBicycleWidget(speedFactor: 1.0, isPlaying: false),
          ),
        ),
      );

      expect(find.byType(PelicanBicycleWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('supports different time of day settings', (
      WidgetTester tester,
    ) async {
      for (final tod in PelicanRideTimeOfDay.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PelicanBicycleWidget(timeOfDay: tod, isPlaying: false),
            ),
          ),
        );
        expect(find.byType(PelicanBicycleWidget), findsOneWidget);
      }
    });
  });

  group('PelicanBicycleDemoScreen', () {
    Widget buildTestWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: const PelicanBicycleDemoScreen(),
      );
    }

    testWidgets('renders correctly with title and controls', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Pelican on Bicycle'), findsOneWidget);
      expect(find.byType(PelicanBicycleWidget), findsOneWidget);
      expect(find.text('Speed & Gear'), findsOneWidget);
      expect(find.text('Environment & Time of Day'), findsOneWidget);
      expect(find.text('Pelican Accessories & Easter Eggs'), findsOneWidget);
      expect(find.text('Bicycle Customization'), findsOneWidget);
    });

    testWidgets('toggles play and pause state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Pedaling'), findsOneWidget);

      // Tap pause button
      final pauseButton = find.byTooltip('Pause');
      expect(pauseButton, findsOneWidget);
      await tester.tap(pauseButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Paused at roadside'), findsOneWidget);

      // Tap play button
      final playButton = find.byTooltip('Play');
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Pedaling'), findsOneWidget);
    });

    testWidgets('switches time of day mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Sunset
      final sunsetSegment = find.text('Sunset');
      expect(sunsetSegment, findsOneWidget);
      await tester.tap(sunsetSegment);
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Starry Night
      final nightSegment = find.text('Starry Night');
      expect(nightSegment, findsOneWidget);
      await tester.tap(nightSegment);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('toggles accessory switches', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final capSwitch = find.widgetWithText(
        SwitchListTile,
        'Retro Cycling Cap (复古骑行帽)',
      );
      expect(capSwitch, findsOneWidget);
      await tester.tap(capSwitch);
      await tester.pump(const Duration(milliseconds: 100));

      final sunglassesSwitch = find.widgetWithText(
        SwitchListTile,
        'Speed Sunglasses (帅气墨镜)',
      );
      expect(sunglassesSwitch, findsOneWidget);
      await tester.tap(sunglassesSwitch);
      await tester.pump(const Duration(milliseconds: 100));

      final fishSwitch = find.widgetWithText(
        SwitchListTile,
        'Fish in Gular Pouch (喉囊小鱼)',
      );
      expect(fishSwitch, findsOneWidget);
      await tester.tap(fishSwitch);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
