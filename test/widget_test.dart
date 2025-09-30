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
  testWidgets('Test app can be initialized.', (WidgetTester tester) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final database = AppDatabase();

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
    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Get the localized app name using AppLocalizations
    final BuildContext context = tester.element(find.byType(MaterialApp).first);

    context.go('/home');
    await tester.pumpAndSettle();

    final appName = AppLocalizations.of(context)!.appName;
    
    // Navigate to /home page (assuming there's a way to trigger navigation)
    // If you need to tap a button or widget to navigate, use:
    // await tester.tap(find.byKey(Key('homeButton')));
    // await tester.pumpAndSettle();
    
    // Verify that the localized app name is displayed
    expect(find.text(appName), findsOneWidget);

    await tester.pumpAndSettle(); 
  });
}
