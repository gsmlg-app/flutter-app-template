import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_bloc/theme_bloc.dart';

class HexSettingsScreen extends StatelessWidget {
  static const name = 'Hex Settings';
  static const path = '/settings/hex';

  const HexSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(SettingsScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(
        idx,
        context,
      ),
      destinations: Destinations.navs(context),
      body: (context) {
        final sharedPrefs = context.read<SharedPreferences>();
        final token = sharedPrefs.getString('HEX_API_KEY');

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                title: Text(context.l10n.settingsTitle),
              ),
              SliverFillRemaining(
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return SettingsList(
                      sections: [
                        SettingsSection(
                          title: Text('Hex API'),
                          tiles: <SettingsTile>[
                            SettingsTile(
                              leading: const Icon(Icons.api),
                              title: Center(
                                child: Text(
                                  'HEX_API_KEY',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              trailing: token == null
                                  ? Text('Not set')
                                  : Text('******'),
                              onPressed: (context) {},
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
