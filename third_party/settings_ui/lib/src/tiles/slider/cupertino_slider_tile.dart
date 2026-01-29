import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/platforms/cupertino_settings_tile.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Cupertino (iOS/macOS) slider tile implementation.
///
/// Provides a slider with iOS/macOS styling using CupertinoSlider.
class CupertinoSliderTile extends StatelessWidget {
  const CupertinoSliderTile({
    required this.title,
    required this.enabled,
    required this.additionalInfo,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    this.leading,
    this.description,
    this.onSliderChanged,
    this.sliderDivisions,
    super.key,
  });

  // Apple HIG specifications
  static const double _horizontalPadding = 16.0;
  static const double _leadingIconSize = 29.0;
  static const double _leadingGap = 12.0;
  static const double _titleFontSize = 17.0;
  static const double _descriptionFontSize = 13.0;
  static const double _cornerRadius = 10.0;

  final Widget? title;
  final Widget? leading;
  final Widget? description;
  final bool enabled;
  final CupertinoSettingsTileAdditionalInfo additionalInfo;
  final double? sliderValue;
  final void Function(double)? onSliderChanged;
  final double sliderMin;
  final double sliderMax;
  final int? sliderDivisions;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    Widget content = Container(
      color: theme.themeData.settingsSectionBackground ??
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      padding: const EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              if (leading != null) ...[
                SizedBox(
                  width: _leadingIconSize,
                  height: _leadingIconSize,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: _leadingIconSize,
                      color: enabled
                          ? theme.themeData.leadingIconsColor
                          : theme.themeData.inactiveTitleColor ??
                              secondaryLabelColor,
                    ),
                    child: Center(child: leading!),
                  ),
                ),
                const SizedBox(width: _leadingGap),
              ],
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: enabled
                        ? theme.themeData.settingsTileTextColor ?? labelColor
                        : theme.themeData.inactiveTitleColor ??
                            secondaryLabelColor,
                    fontSize: _titleFontSize,
                    letterSpacing: -0.4,
                  ),
                  child: title ?? const SizedBox.shrink(),
                ),
              ),
              // Current value
              Text(
                sliderValue?.toStringAsFixed(sliderDivisions != null ? 0 : 1) ??
                    '',
                style: TextStyle(
                  color: enabled
                      ? CupertinoColors.activeBlue.resolveFrom(context)
                      : secondaryLabelColor,
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: textScaler.scale(8)),
          // Slider
          CupertinoSlider(
            value: sliderValue ?? sliderMin,
            min: sliderMin,
            max: sliderMax,
            divisions: sliderDivisions,
            onChanged: enabled ? onSliderChanged : null,
          ),
        ],
      ),
    );

    if (!Platform.isIOS) {
      content = Material(color: Colors.transparent, child: content);
    }

    return IgnorePointer(
      ignoring: !enabled,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: additionalInfo.enableTopBorderRadius
              ? const Radius.circular(_cornerRadius)
              : Radius.zero,
          bottom: additionalInfo.enableBottomBorderRadius
              ? const Radius.circular(_cornerRadius)
              : Radius.zero,
        ),
        child: Column(
          children: [
            content,
            if (description != null) _buildDescription(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, SettingsTheme theme) {
    final textScaler = MediaQuery.of(context).textScaler;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: _horizontalPadding + 2,
        right: _horizontalPadding + 2,
        top: textScaler.scale(6),
        bottom: additionalInfo.needToShowDivider ? 20 : textScaler.scale(6),
      ),
      decoration: BoxDecoration(color: theme.themeData.settingsListBackground),
      child: DefaultTextStyle(
        style: TextStyle(
          color: theme.themeData.titleTextColor ??
              CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: _descriptionFontSize,
        ),
        child: description!,
      ),
    );
  }
}
