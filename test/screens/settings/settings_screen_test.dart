import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

void main() {
  group('SettingsScreen', () {
    late DmThemeBloc themeBloc;
    late GamepadBloc gamepadBloc;
    late SharedPreferences sharedPreferences;
    final navigatorKey = GlobalKey<NavigatorState>();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      themeBloc = DmThemeBloc(prefs: sharedPreferences);
      gamepadBloc = GamepadBloc(
        navigatorKey: navigatorKey,
        routeNames: const [],
      );
    });

    tearDown(() {
      themeBloc.close();
      gamepadBloc.close();
      sharedPreferences.clear();
    });

    Widget buildWidget() {
      return RepositoryProvider<SharedPreferences>(
        create: (context) => sharedPreferences,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DmThemeBloc>.value(value: themeBloc),
            BlocProvider<GamepadBloc>.value(value: gamepadBloc),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
    }

    testWidgets('renders correctly with basic components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('displays settings sections', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('App Setting'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows appearance option', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.brightness_medium), findsOneWidget);
    });

    testWidgets('shows accent color option', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('app settings tile has correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.api), findsOneWidget);
    });
  });
}
