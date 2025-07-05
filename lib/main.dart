import 'package:app_locale/app_locale.dart';
import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart' as logging;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  logging.hierarchicalLoggingEnabled = true;

  final sharedPrefs = await SharedPreferences.getInstance();
  // final applicationSupportDirectory = await getApplicationSupportDirectory();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (BuildContext context) => ThemeBloc(sharedPrefs),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: const App(),
      ),
    ),
  );
}
