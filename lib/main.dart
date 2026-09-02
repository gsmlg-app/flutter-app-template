import 'dart:io';

import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_provider/app_provider.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final applicationSupportDirectory = await getApplicationSupportDirectory();

  // Initialize logging
  final logger = AppLogger();
  logger.initialize(level: kDebugMode ? LogLevel.debug : LogLevel.info);
  final directory = Directory(
    path.join(applicationSupportDirectory.path, 'flutter_app_template'),
  );
  await directory.create(recursive: true);
  final logFile = File(path.join(directory.path, 'app.log'));
  logger.logStream.listen((record) {
    final log =
        '${record.loggerName} ${record.level.name} [${record.time}]: ${record.message}\n';
    logFile.writeAsStringSync(log, mode: FileMode.append);
  });
  // Use logger
  logger.i('App started');

  final sharedPrefs = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final vault = SecureStorageVaultRepository();

  runApp(
    MainProvider(
      sharedPrefs: sharedPrefs,
      database: database,
      vault: vault,
      child: CrashReportingWidget(child: const App()),
    ),
  );
}
