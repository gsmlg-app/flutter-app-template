import 'package:flutter/cupertino.dart';
import 'package:settings_ui/src/list/abstract_settings_list.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Cupertino (iOS/macOS) settings list implementation.
///
/// Follows Apple Human Interface Guidelines for iOS Settings:
/// - Background: systemGroupedBackground (light gray)
/// - Max content width: 640pt on iPad (centered)
/// - No additional padding (sections handle their own margins)
///
/// See: https://developer.apple.com/design/human-interface-guidelines/lists
class CupertinoSettingsList extends AbstractSettingsList {
  const CupertinoSettingsList({
    required super.sections,
    super.shrinkWrap,
    super.physics,
    super.platform,
    super.contentPadding,
    super.key,
  });

  // Apple HIG specifications
  static const double _maxContentWidthiPad = 640.0;

  @override
  Widget build(BuildContext context) {
    final effectivePlatform = platform ?? DevicePlatform.iOS;
    final themeData = SettingsThemeData.withContext(context, effectivePlatform);

    // Use Cupertino system grouped background
    final backgroundColor = themeData.settingsListBackground ??
        CupertinoColors.systemGroupedBackground.resolveFrom(context);

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
    // On larger screens (iPad), constrain content width
    if (maxWidth > _maxContentWidthiPad) {
      final horizontalPadding = (maxWidth - _maxContentWidthiPad) / 2;
      return EdgeInsets.symmetric(horizontal: horizontalPadding);
    }
    return EdgeInsets.zero;
  }
}
