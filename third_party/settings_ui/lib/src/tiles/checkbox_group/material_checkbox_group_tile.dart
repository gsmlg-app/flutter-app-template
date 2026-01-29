import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design checkbox group tile implementation.
///
/// Provides a group of checkboxes with Material Design 3 styling for Android, Linux, and Web.
class MaterialCheckboxGroupTile extends StatelessWidget {
  const MaterialCheckboxGroupTile({
    required this.title,
    required this.enabled,
    this.leading,
    this.description,
    this.checkboxOptions,
    this.checkboxValues,
    this.onCheckboxChanged,
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
  final List<SettingsOption>? checkboxOptions;
  final Set<String>? checkboxValues;
  final void Function(Set<String>)? onCheckboxChanged;

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
                          : theme.themeData.inactiveSubtitleColor ??
                              colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.38),
                      fontSize: _descriptionFontSize,
                    ),
                    child: description!,
                  ),
                ),
              // Checkbox options
              ...?checkboxOptions?.map(
                (option) => CheckboxListTile(
                  title: Row(
                    children: [
                      if (option.icon != null) ...[
                        option.icon!,
                        const SizedBox(width: 12),
                      ],
                      Text(option.label),
                    ],
                  ),
                  value: checkboxValues?.contains(option.value) ?? false,
                  onChanged: enabled
                      ? (checked) {
                          final newValues =
                              Set<String>.from(checkboxValues ?? {});
                          if (checked == true) {
                            newValues.add(option.value);
                          } else {
                            newValues.remove(option.value);
                          }
                          onCheckboxChanged?.call(newValues);
                        }
                      : null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
