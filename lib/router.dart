import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/app/error_screen.dart';
import 'package:flutter_app_template/screens/app/splash_screen.dart';
import 'package:flutter_app_template/screens/home/home_screen.dart';
import 'package:flutter_app_template/screens/settings/accent_color_settings_screen.dart';
import 'package:flutter_app_template/screens/settings/app_settings_screen.dart';
import 'package:flutter_app_template/screens/settings/appearance_settings_screen.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_app_template/screens/showcase/adaptive_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/artwork_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/client_info_screen.dart';
import 'package:flutter_app_template/screens/showcase/feedback_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/form_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_app_template/screens/showcase/vault_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/webview_demo_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>(
    debugLabel: 'routerKey',
  );

  static GoRouter router = GoRouter(
    navigatorKey: key,
    debugLogDiagnostics: true,
    initialLocation: SplashScreen.path,
    routes: routes,
    errorBuilder: (context, state) {
      return ErrorScreen(routerState: state);
    },
  );

  static List<GoRoute> routes = [
    GoRoute(
      name: SplashScreen.name,
      path: SplashScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      name: HomeScreen.name,
      path: HomeScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      name: ShowcaseScreen.name,
      path: ShowcaseScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const ShowcaseScreen(),
        );
      },
      routes: [
        GoRoute(
          name: FeedbackDemoScreen.name,
          path: FeedbackDemoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const FeedbackDemoScreen(),
            );
          },
        ),
        GoRoute(
          name: AdaptiveDemoScreen.name,
          path: AdaptiveDemoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AdaptiveDemoScreen(),
            );
          },
        ),
        GoRoute(
          name: ArtworkDemoScreen.name,
          path: ArtworkDemoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const ArtworkDemoScreen(),
            );
          },
        ),
        GoRoute(
          name: WebViewDemoScreen.name,
          path: WebViewDemoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const WebViewDemoScreen(),
            );
          },
        ),
        GoRoute(
          name: ClientInfoScreen.name,
          path: ClientInfoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const ClientInfoScreen(),
            );
          },
        ),
        GoRoute(
          name: FormDemoScreen.name,
          path: FormDemoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const FormDemoScreen(),
            );
          },
        ),
        GoRoute(
          name: VaultDemoScreen.name,
          path: VaultDemoScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const VaultDemoScreen(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      name: SettingsScreen.name,
      path: SettingsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SettingsScreen(),
        );
      },
      routes: [
        GoRoute(
          name: AppSettingsScreen.name,
          path: AppSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: AppearanceSettingsScreen.name,
          path: AppearanceSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppearanceSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: AccentColorSettingsScreen.name,
          path: AccentColorSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AccentColorSettingsScreen(),
            );
          },
        ),
      ],
    ),
  ];
}
