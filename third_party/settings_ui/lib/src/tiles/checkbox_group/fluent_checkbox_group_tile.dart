import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Fluent Design (Windows 11) checkbox group tile implementation.
///
/// Provides a group of checkboxes with Windows 11 Fluent styling.
class FluentCheckboxGroupTile extends StatelessWidget {
  const FluentCheckboxGroupTile({
    required this.title,
    required this.enabled,
    this.leading,
    this.description,
    this.checkboxOptions,
    this.checkboxValues,
    this.onCheckboxChanged,
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
  final List<SettingsOption>? checkboxOptions;
  final Set<String>? checkboxValues;
  final void Function(Set<String>)? onCheckboxChanged;

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
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
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
              const SizedBox(height: 8),
              // Checkbox options with Fluent styling
              ...?checkboxOptions?.map(
                (option) {
                  final isChecked =
                      checkboxValues?.contains(option.value) ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: enabled
                          ? () {
                              final newValues =
                                  Set<String>.from(checkboxValues ?? {});
                              if (isChecked) {
                                newValues.remove(option.value);
                              } else {
                                newValues.add(option.value);
                              }
                              onCheckboxChanged?.call(newValues);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: enabled
                                  ? (checked) {
                                      final newValues = Set<String>.from(
                                          checkboxValues ?? {});
                                      if (checked == true) {
                                        newValues.add(option.value);
                                      } else {
                                        newValues.remove(option.value);
                                      }
                                      onCheckboxChanged?.call(newValues);
                                    }
                                  : null,
                              activeColor: colorScheme.primary,
                            ),
                            if (option.icon != null) ...[
                              option.icon!,
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  color: enabled
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.38),
                                  fontSize: _headerFontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
