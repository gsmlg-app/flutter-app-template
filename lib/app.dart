import 'package:app_locale/app_locale.dart';
import 'package:app_provider/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';

import 'destination.dart';
import 'router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();

    return BlocBuilder<ThemeBloc, ThemeState>(
      bloc: themeBloc,
      builder: (context, state) {
        return _AppContent(themeState: state);
      },
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent({required this.themeState});

  final ThemeState themeState;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    return AppBlocProvider(
      navigatorKey: AppRouter.key,
      routeNames: Destinations.routeNames,
      child: MaterialApp.router(
        key: const Key('app'),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        onGenerateTitle: (context) => context.l10n.appName,
        theme: themeState.theme.lightTheme,
        darkTheme: themeState.theme.darkTheme,
        themeMode: themeState.themeMode,
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
      ),
    );
  }
}
