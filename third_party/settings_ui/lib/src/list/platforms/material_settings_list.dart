import 'package:flutter/material.dart';
import 'package:settings_ui/src/list/abstract_settings_list.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design 3 settings list implementation.
///
/// Follows M3 List specifications:
/// - Background: surface color
/// - Max content width: 840dp (centered on larger screens)
/// - Vertical padding: 8dp top/bottom
///
/// See: https://m3.material.io/components/lists/specs
class MaterialSettingsList extends AbstractSettingsList {
  const MaterialSettingsList({
    required super.sections,
    super.shrinkWrap,
    super.physics,
    super.platform,
    super.contentPadding,
    super.key,
  });

  // M3 specifications
  static const double _maxContentWidth = 840.0;
  static const double _verticalPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final effectivePlatform = platform ?? DevicePlatform.android;
    final themeData = SettingsThemeData.withContext(context, effectivePlatform);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        color: themeData.settingsListBackground ?? colorScheme.surface,
        width: constraints.maxWidth,
        alignment: Alignment.center,
        child: SettingsTheme(
          themeData: themeData,
          platform: effectivePlatform,
          child: ListView.builder(
            physics: physics,
            shrinkWrap: shrinkWrap,
            itemCount: sections.length,
            padding: contentPadding ?? _calculateDefaultPadding(constraints),
            itemBuilder: (BuildContext context, int index) {
              return sections[index];
            },
          ),
        ),
      ),
    );
  }

  EdgeInsets _calculateDefaultPadding(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    if (maxWidth > _maxContentWidth) {
      final horizontalPadding = (maxWidth - _maxContentWidth) / 2;
      return EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: _verticalPadding,
      );
    }
    return EdgeInsets.symmetric(vertical: _verticalPadding);
  }
}
