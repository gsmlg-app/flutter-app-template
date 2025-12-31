import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  static const name = 'Appearance Settings';
  static const path = 'appearance';

  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(SettingsScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        final themeBloc = context.read<ThemeBloc>();

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(context.l10n.appearance)),
              SliverFillRemaining(
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  bloc: themeBloc,
                  builder: (context, state) {
                    return SettingsList(
                      sections: [
                        SettingsSection(
                          title: Text(context.l10n.appearance),
                          tiles: <SettingsTile>[
                            SettingsTile(
                              leading: const Icon(Icons.light_mode),
                              title: Text(context.l10n.lightTheme),
                              trailing: state.themeMode == ThemeMode.light
                                  ? const Icon(Icons.check)
                                  : null,
                              onPressed: (context) {
                                themeBloc.add(
                                  const ChangeThemeMode(ThemeMode.light),
                                );
                              },
                            ),
                            SettingsTile(
                              leading: const Icon(Icons.dark_mode),
                              title: Text(context.l10n.darkTheme),
                              trailing: state.themeMode == ThemeMode.dark
                                  ? const Icon(Icons.check)
                                  : null,
                              onPressed: (context) {
                                themeBloc.add(
                                  const ChangeThemeMode(ThemeMode.dark),
                                );
                              },
                            ),
                            SettingsTile(
                              leading: const Icon(Icons.brightness_auto),
                              title: Text(context.l10n.systemTheme),
                              trailing: state.themeMode == ThemeMode.system
                                  ? const Icon(Icons.check)
                                  : null,
                              onPressed: (context) {
                                themeBloc.add(
                                  const ChangeThemeMode(ThemeMode.system),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
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
