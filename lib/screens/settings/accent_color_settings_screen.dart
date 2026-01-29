import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
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
                          tiles: <AbstractSettingsTile>[
                            CustomSettingsTile(
                              child: _AccentColorPicker(
                                themes: themeList,
                                currentTheme: currentTheme,
                                isLight: isLight,
                                onThemeChanged: (theme) {
                                  themeBloc.add(ChangeTheme(theme));
                                },
                              ),
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

/// A horizontal accent color picker with colored circles.
class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({
    required this.themes,
    required this.currentTheme,
    required this.isLight,
    required this.onThemeChanged,
  });

  final List<AppTheme> themes;
  final AppTheme currentTheme;
  final bool isLight;
  final ValueChanged<AppTheme> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color circles row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: themes.map((theme) {
              final colorScheme = isLight
                  ? theme.lightTheme.colorScheme
                  : theme.darkTheme.colorScheme;
              final isSelected = currentTheme.name == theme.name;

              return _ColorOption(
                color: colorScheme.primary,
                isSelected: isSelected,
                onTap: () => onThemeChanged(theme),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Current theme name
          Text(
            currentTheme.name,
            style: TextStyle(
              fontSize: 13,
              color: labelColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: CupertinoColors.white,
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                CupertinoIcons.checkmark,
                color: CupertinoColors.white,
                size: 16,
              )
            : null,
      ),
    );
  }
}
