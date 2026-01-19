import 'package:app_gamepad/app_gamepad.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_bloc/nav_bloc.dart';
import 'package:provider/provider.dart';
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

class _AppContent extends StatefulWidget {
  const _AppContent({required this.themeState});

  final ThemeState themeState;

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late final NavigationBloc _navigationBloc;
  late final GamepadController _gamepadController;

  @override
  void initState() {
    super.initState();
    // Initialize NavigationBloc with destinations
    _navigationBloc = NavigationBloc(
      navigatorKey: AppRouter.key,
      destinations: Destinations.navs(context),
    );
    // Initialize GamepadController with NavigationBloc
    _gamepadController = GamepadController(navigationBloc: _navigationBloc);
  }

  @override
  void dispose() {
    _gamepadController.dispose();
    _navigationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    return MultiBlocProvider(
      providers: [BlocProvider<NavigationBloc>.value(value: _navigationBloc)],
      child: ChangeNotifierProvider<GamepadController>.value(
        value: _gamepadController,
        child: MaterialApp.router(
          key: const Key('app'),
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          onGenerateTitle: (context) => context.l10n.appName,
          theme: widget.themeState.theme.lightTheme,
          darkTheme: widget.themeState.theme.darkTheme,
          themeMode: widget.themeState.themeMode,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      ),
    );
  }
}
