import 'package:app_database/app_database.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_provider/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  final logger = AppLogger();
  logger.initialize(
    level: LogLevel.debug,
  );
  logger.logStream.listen((record) {
    print(
        '${record.loggerName} ${record.level.name} [${record.time}]: ${record.message}');
  });
  // Use logger
  logger.i('App started');

  final sharedPrefs = await SharedPreferences.getInstance();
  final database = AppDatabase();
  // final applicationSupportDirectory = await getApplicationSupportDirectory();

  runApp(
    MainProvider(
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
    ),
  );
}
