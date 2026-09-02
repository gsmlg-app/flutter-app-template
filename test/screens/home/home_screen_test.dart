import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/home/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locale/app_locale.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders correctly with basic components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      expect(find.text('Flutter App Template'), findsOneWidget);
    });

    testWidgets('displays quick navigation cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: const HomeScreen(),
        ),
      );

      expect(find.text('Showcase'), findsAtLeastNWidgets(1));
      expect(find.text('Settings'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays architecture packages', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: const HomeScreen(),
        ),
      );

      expect(find.text('Architecture'), findsOneWidget);
      expect(find.text('app_bloc'), findsOneWidget);
      expect(find.text('app_lib'), findsOneWidget);
      expect(find.text('app_widget'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('displays tech stack chips', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: const HomeScreen(),
        ),
      );

      expect(find.text('Tech Stack'), findsOneWidget);
      expect(find.text('Flutter 3.8+'), findsOneWidget);
      expect(find.text('BLoC / Cubit'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('handles landscape orientation correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
