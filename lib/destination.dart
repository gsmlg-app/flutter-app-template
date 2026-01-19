import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/home/home_screen.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_bloc/nav_bloc.dart';

class Destinations {
  static List<NavigationDestination> navs(BuildContext context) =>
      <NavigationDestination>[
        NavigationDestination(
          key: const Key(HomeScreen.name),
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: context.l10n.navHome,
        ),
        NavigationDestination(
          key: const Key(ShowcaseScreen.name),
          icon: const Icon(Icons.widgets_outlined),
          selectedIcon: const Icon(Icons.widgets),
          label: context.l10n.navShowcase,
        ),
        NavigationDestination(
          key: const Key(SettingsScreen.name),
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: context.l10n.navSetting,
        ),
      ];

  static int indexOf(Key key, BuildContext context) {
    return navs(context).indexWhere((element) => element.key == key);
  }

  /// Handle navigation index change - dispatches to NavigationBloc
  static void changeHandler(int idx, BuildContext context) {
    context.read<NavigationBloc>().add(NavigateToIndex(idx));
  }
}
