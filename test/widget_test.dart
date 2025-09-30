import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_locale/gen_l10n/app_localizations.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_provider/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences sharedPrefs;
  late AppDatabase database;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
    database = AppDatabase.forTesting();
  });

  tearDown(() async {
    await database.close();
    await sharedPrefs.clear();
  });

  testWidgets('Test app can be initialized.', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final appMain = MainProvider(
      sharedPrefs: sharedPrefs,
      database: database,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: CrashReportingWidget(
          child: const App(),
        ),
      ),
    );

    await tester.pumpWidget(appMain);
    await tester.pumpAndSettle();

    // Find a widget that's definitely rendered and get its context
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    // Or use any other widget type that you know exists in your app

    final textOnScreen = AppLocalizations.of(context)!.welcomeHome;

    await Timer(
      const Duration(milliseconds: 1_100),
      () {},
    );

    // Navigate to /home page (assuming there's a way to trigger navigation)
    // If you need to tap a button or widget to navigate, use:
    // await tester.tap(find.byKey(Key('homeButton')));
    // await tester.pumpAndSettle();

    // Verify that the localized app name is displayed
    expect(find.text(textOnScreen), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
