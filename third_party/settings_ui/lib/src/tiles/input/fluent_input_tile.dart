import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Fluent Design (Windows 11) input tile implementation.
///
/// Provides a text field with Windows 11 Fluent styling.
class FluentInputTile extends StatelessWidget {
  const FluentInputTile({
    required this.title,
    required this.enabled,
    this.leading,
    this.description,
    this.inputValue,
    this.onInputChanged,
    this.inputHint,
    this.inputKeyboardType,
    this.inputMaxLength,
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
  final String? inputValue;
  final void Function(String)? onInputChanged;
  final String? inputHint;
  final TextInputType? inputKeyboardType;
  final int? inputMaxLength;

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
              // Title row with leading icon
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
                ],
              ),
              const SizedBox(height: 12),
              // Text field with Fluent styling
              TextFormField(
                initialValue: inputValue,
                onChanged: enabled ? onInputChanged : null,
                enabled: enabled,
                keyboardType: inputKeyboardType,
                maxLength: inputMaxLength,
                decoration: InputDecoration(
                  hintText: inputHint,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  counterText: inputMaxLength != null ? null : '',
                ),
              ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
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
