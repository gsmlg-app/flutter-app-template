import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Fluent Design (Windows 11) slider tile implementation.
///
/// Provides a slider with Windows 11 Fluent styling.
class FluentSliderTile extends StatelessWidget {
  const FluentSliderTile({
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

  // Fluent Design specifications
  static const double _borderRadius = 4.0;
  static const double _horizontalPadding = 16.0;
  static const double _iconContainerSize = 36.0;
  static const double _iconSize = 20.0;
  static const double _contentGap = 16.0;
  static const double _headerFontSize = 14.0;
  static const double _descriptionFontSize = 12.0;

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
    final brightness = Theme.of(context).brightness;

    final cardColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
        : colorScheme.surfaceContainerLowest;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(_horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with leading icon and value
              Row(
                children: [
                  if (leading != null) ...[
                    _buildLeadingIcon(context, theme, colorScheme),
                    const SizedBox(width: _contentGap),
                  ],
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: enabled
                            ? theme.themeData.settingsTileTextColor ??
                                colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: _headerFontSize,
                        fontWeight: FontWeight.w600,
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
                      fontSize: _headerFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Slider with Fluent styling
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  thumbColor: colorScheme.primary,
                  overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: sliderValue ?? sliderMin,
                  min: sliderMin,
                  max: sliderMax,
                  divisions: sliderDivisions,
                  onChanged: enabled ? onSliderChanged : null,
                ),
              ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: enabled
                          ? theme.themeData.tileDescriptionTextColor ??
                              colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
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

  Widget _buildLeadingIcon(
    BuildContext context,
    SettingsTheme theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: _iconContainerSize,
      height: _iconContainerSize,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: IconTheme(
        data: IconThemeData(
          size: _iconSize,
          color: enabled
              ? theme.themeData.leadingIconsColor ?? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        child: Center(child: leading!),
      ),
    );
  }
}
