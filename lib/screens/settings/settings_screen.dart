import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/accent_color_settings_screen.dart';
import 'package:flutter_app_template/screens/settings/app_settings_screen.dart';
import 'package:flutter_app_template/screens/settings/appearance_settings_screen.dart';
import 'package:flutter_app_template/screens/settings/controller_settings_screen.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';

class SettingsScreen extends StatelessWidget {
  static const name = 'Settings';
  static const path = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DmScaffold(
      selectedIndex: Destinations.indexOf(const Key(name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        final themeBloc = context.read<DmThemeBloc>();

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(context.l10n.settingsTitle)),
              SliverFillRemaining(
                child: BlocBuilder<DmThemeBloc, DmThemeState>(
                  bloc: themeBloc,
                  builder: (context, themeState) {
                    return BlocBuilder<GamepadBloc, GamepadState>(
                      builder: (context, gamepadState) {
                        return SettingsList(
                          sections: [
                            SettingsSection(
                              title: Text('App Setting'),
                              tiles: <SettingsTile>[
                                SettingsTile.navigation(
                                  leading: const Icon(Icons.api),
                                  title: Text('App Setting'),
                                  onPressed: (context) {
                                    context.goNamed(AppSettingsScreen.name);
                                  },
                                ),
                              ],
                            ),
                            SettingsSection(
                              title: Text(context.l10n.smenuTheme),
                              tiles: <SettingsTile>[
                                SettingsTile.navigation(
                                  leading: const Icon(Icons.brightness_medium),
                                  title: Text(context.l10n.appearance),
                                  value: themeState.themeMode.icon,
                                  onPressed: (context) {
                                    context.goNamed(
                                      AppearanceSettingsScreen.name,
                                    );
                                  },
                                ),
                                SettingsTile.navigation(
                                  leading: const Icon(Icons.palette),
                                  title: Text(context.l10n.accentColor),
                                  value: Text(themeState.themeName),
                                  onPressed: (context) {
                                    context.goNamed(
                                      AccentColorSettingsScreen.name,
                                    );
                                  },
                                ),
                              ],
                            ),
                            SettingsSection(
                              title: Text(context.l10n.controllerSettings),
                              tiles: <SettingsTile>[
                                SettingsTile.navigation(
                                  leading: const Icon(Icons.gamepad),
                                  title: Text(context.l10n.controllerSettings),
                                  value: Text(
                                    gamepadState.config.enabled
                                        ? 'Enabled'
                                        : 'Disabled',
                                  ),
                                  onPressed: (context) {
                                    context.goNamed(
                                      ControllerSettingsScreen.name,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}
