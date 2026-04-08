import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatelessWidget {
  static const name = 'App Settings';
  static const path = 'app';
  static const fullPath = '${SettingsScreen.path}/$name';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DmScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(SettingsScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        final sharedPrefs = context.read<SharedPreferences>();
        final appName = sharedPrefs.getString('APP_NAME');

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(context.l10n.settingsTitle)),
              SliverFillRemaining(
                child: BlocBuilder<DmThemeBloc, DmThemeState>(
                  builder: (context, state) {
                    return SettingsList(
                      sections: [
                        SettingsSection(
                          title: Text('APP_NAME'),
                          tiles: <SettingsTile>[
                            SettingsTile(
                              leading: const Icon(Icons.api),
                              title: Center(
                                child: Text(
                                  'APP_NAME',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              trailing: appName == null
                                  ? Text('N/A')
                                  : Text(appName),
                              onPressed: (context) {
                                showDmDialog(
                                  context: context,
                                  title: Text(context.l10n.appName),
                                  content: Text(context.l10n.welcomeHome),
                                  actions: [
                                    DmDialogAction(
                                      onPressed: (context) {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(context.l10n.ok),
                                    ),
                                    DmDialogAction(
                                      onPressed: (context) {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(context.l10n.cancel),
                                    ),
                                  ],
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
