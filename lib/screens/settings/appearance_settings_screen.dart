import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/cupertino.dart';
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
                          tiles: <AbstractSettingsTile>[
                            CustomSettingsTile(
                              child: _AppearancePicker(
                                currentMode: state.themeMode,
                                onModeChanged: (mode) {
                                  themeBloc.add(ChangeThemeMode(mode));
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

/// A horizontal appearance mode picker with visual previews.
class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker({
    required this.currentMode,
    required this.onModeChanged,
  });

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AppearanceOption(
            label: context.l10n.lightTheme,
            isSelected: currentMode == ThemeMode.light,
            onTap: () => onModeChanged(ThemeMode.light),
            preview: _buildPreview(context, Brightness.light),
            labelColor: labelColor,
          ),
          const SizedBox(width: 16),
          _AppearanceOption(
            label: context.l10n.darkTheme,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => onModeChanged(ThemeMode.dark),
            preview: _buildPreview(context, Brightness.dark),
            labelColor: labelColor,
          ),
          const SizedBox(width: 16),
          _AppearanceOption(
            label: context.l10n.systemTheme,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => onModeChanged(ThemeMode.system),
            preview: _buildAutoPreview(context),
            labelColor: labelColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFE8E8ED) : const Color(0xFF2D2D2D);
    final windowBg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final titleBarColor =
        isLight ? const Color(0xFFF0F0F0) : const Color(0xFF3A3A3A);
    final sidebarColor =
        isLight ? const Color(0xFFF5F5F7) : const Color(0xFF2A2A2A);
    final accentColor = CupertinoColors.activeBlue;

    return Container(
      width: 80,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: windowBg,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Title bar with traffic lights
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: titleBarColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                children: [
                  _trafficLight(const Color(0xFFFF5F57)),
                  const SizedBox(width: 2),
                  _trafficLight(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 2),
                  _trafficLight(const Color(0xFF28CA41)),
                ],
              ),
            ),
            // Content area with sidebar
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 18,
                    color: sidebarColor,
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: windowBg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoPreview(BuildContext context) {
    // Split preview showing both light and dark
    return Container(
      width: 80,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: _buildPreview(context, Brightness.light)),
          Expanded(child: _buildPreview(context, Brightness.dark)),
        ],
      ),
    );
  }

  Widget _trafficLight(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.preview,
    required this.labelColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget preview;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: preview,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
