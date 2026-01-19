import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';

class AccentColorSettingsScreen extends StatelessWidget {
  static const name = 'Accent Color Settings';
  static const path = 'accent-color';

  const AccentColorSettingsScreen({super.key});

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
        final isLight = Theme.of(context).brightness == Brightness.light;

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(context.l10n.accentColor)),
              SliverFillRemaining(
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  bloc: themeBloc,
                  builder: (context, state) {
                    final currentTheme = state.theme;

                    return SettingsList(
                      sections: [
                        SettingsSection(
                          title: Text(context.l10n.accentColor),
                          tiles: themeList.map<SettingsTile>((appTheme) {
                            final isSelected =
                                currentTheme.name == appTheme.name;
                            final colorScheme = isLight
                                ? appTheme.lightTheme.colorScheme
                                : appTheme.darkTheme.colorScheme;

                            return SettingsTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(appTheme.name),
                              trailing: isSelected
                                  ? const Icon(Icons.check)
                                  : null,
                              value: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: colorScheme.secondary,
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: (context) {
                                themeBloc.add(ChangeTheme(appTheme));
                              },
                            );
                          }).toList(),
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
