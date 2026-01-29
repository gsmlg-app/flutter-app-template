import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/tiles/platforms/cupertino_settings_tile.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// A custom settings tile that allows embedding any widget.
///
/// This tile type is useful when you need to create a completely custom
/// tile layout that doesn't fit the standard tile patterns (simple, switch,
/// navigation, etc.).
///
/// The tile automatically applies the correct section background color
/// based on the current platform and theme.
///
/// Example:
/// ```dart
/// CustomSettingsTile(
///   child: MyCustomColorPicker(
///     currentColor: selectedColor,
///     onColorChanged: (color) => setState(() => selectedColor = color),
///   ),
/// )
/// ```
class CustomSettingsTile extends AbstractSettingsTile {
  /// Creates a custom settings tile with the given child widget.
  const CustomSettingsTile({
    required this.child,
    super.key,
  }) : super(
          title: null,
          tileType: SettingsTileType.simpleTile,
        );

  /// The custom widget to display as the tile content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.maybeOf(context);
    final platform = theme?.platform ?? DevicePlatform.detect();

    // Get appropriate background color based on platform
    final Color backgroundColor;
    switch (platform) {
      case DevicePlatform.iOS:
      case DevicePlatform.macOS:
        backgroundColor = theme?.themeData.settingsSectionBackground ??
            CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context);
      default:
        backgroundColor =
            theme?.themeData.settingsSectionBackground ?? Colors.transparent;
    }

    // Get border radius info for Cupertino platforms
    final additionalInfo =
        CupertinoSettingsTileAdditionalInfo.of(context);
    final borderRadius = (platform == DevicePlatform.iOS ||
            platform == DevicePlatform.macOS)
        ? BorderRadius.vertical(
            top: additionalInfo.enableTopBorderRadius
                ? const Radius.circular(10)
                : Radius.zero,
            bottom: additionalInfo.enableBottomBorderRadius
                ? const Radius.circular(10)
                : Radius.zero,
          )
        : BorderRadius.zero;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: backgroundColor,
        child: child,
      ),
    );
  }
}
