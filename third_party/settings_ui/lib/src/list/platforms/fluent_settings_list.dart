import 'package:flutter/material.dart';
import 'package:settings_ui/src/list/abstract_settings_list.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Fluent Design (Windows 11) settings list implementation.
///
/// Follows Windows 11 Settings app specifications:
/// - Background: Layer background (subtle gray)
/// - Max content width: 1000dp (responsive layout)
/// - Horizontal padding: 24dp minimum, responsive
/// - Vertical padding: 16dp top, 24dp bottom
///
/// See: https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/layering
class FluentSettingsList extends AbstractSettingsList {
  const FluentSettingsList({
    required super.sections,
    super.shrinkWrap,
    super.physics,
    super.platform,
    super.contentPadding,
    super.key,
  });

  // Fluent Design specifications
  static const double _maxContentWidth = 1000.0;
  static const double _minHorizontalPadding = 24.0;
  static const double _topPadding = 16.0;
  static const double _bottomPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final effectivePlatform = platform ?? DevicePlatform.windows;
    final themeData = SettingsThemeData.withContext(context, effectivePlatform);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    // Fluent uses subtle layer background
    final backgroundColor = themeData.settingsListBackground ??
        (brightness == Brightness.dark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surface);

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        color: backgroundColor,
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
    if (maxWidth > _maxContentWidth + (_minHorizontalPadding * 2)) {
      final horizontalPadding = (maxWidth - _maxContentWidth) / 2;
      return EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: _topPadding,
        bottom: _bottomPadding,
      );
    }
    return EdgeInsets.only(
      left: _minHorizontalPadding,
      right: _minHorizontalPadding,
      top: _topPadding,
      bottom: _bottomPadding,
    );
  }
}
