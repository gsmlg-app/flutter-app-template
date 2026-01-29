import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design slider tile implementation.
///
/// Provides a slider with Material Design 3 styling for Android, Linux, and Web.
class MaterialSliderTile extends StatelessWidget {
  const MaterialSliderTile({
    required this.title,
    required this.enabled,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    this.leading,
    this.description,
    this.onSliderChanged,
    this.sliderDivisions,
    super.key,
  });

  // M3 specifications
  static const double _horizontalPadding = 16.0;
  static const double _leadingIconSize = 24.0;
  static const double _leadingGap = 16.0;
  static const double _titleFontSize = 16.0;
  static const double _descriptionFontSize = 14.0;

  final Widget? title;
  final Widget? leading;
  final Widget? description;
  final bool enabled;
  final double? sliderValue;
  final void Function(double)? onSliderChanged;
  final double sliderMin;
  final double sliderMax;
  final int? sliderDivisions;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with leading icon
              Row(
                children: [
                  if (leading != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: _leadingIconSize,
                        color: enabled
                            ? theme.themeData.leadingIconsColor ??
                                colorScheme.onSurfaceVariant
                            : theme.themeData.inactiveTitleColor ??
                                colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: _leadingGap),
                  ],
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: enabled
                            ? theme.themeData.settingsTileTextColor ??
                                colorScheme.onSurface
                            : theme.themeData.inactiveTitleColor ??
                                colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: _titleFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                      child: title ?? const SizedBox.shrink(),
                    ),
                  ),
                  // Current value display
                  Text(
                    sliderValue?.toStringAsFixed(
                            sliderDivisions != null ? 0 : 1) ??
                        '',
                    style: TextStyle(
                      color: enabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Slider
              Slider(
                value: sliderValue ?? sliderMin,
                min: sliderMin,
                max: sliderMax,
                divisions: sliderDivisions,
                onChanged: enabled ? onSliderChanged : null,
              ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: enabled
                          ? theme.themeData.tileDescriptionTextColor ??
                              colorScheme.onSurfaceVariant
                          : theme.themeData.inactiveSubtitleColor ??
                              colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.38),
                      fontSize: _descriptionFontSize,
                    ),
                    child: description!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
