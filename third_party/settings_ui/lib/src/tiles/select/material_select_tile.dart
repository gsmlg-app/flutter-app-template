import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design select/dropdown tile implementation.
///
/// Provides a dropdown selection with Material Design 3 styling for Android, Linux, and Web.
/// Shows a bottom sheet with options when tapped.
class MaterialSelectTile extends StatelessWidget {
  const MaterialSelectTile({
    required this.title,
    required this.enabled,
    this.leading,
    this.description,
    this.selectOptions,
    this.selectValue,
    this.onSelectChanged,
    super.key,
  });

  // M3 specifications
  static const double _horizontalPadding = 16.0;
  static const double _leadingIconSize = 24.0;
  static const double _leadingGap = 16.0;
  static const double _trailingGap = 16.0;
  static const double _titleFontSize = 16.0;
  static const double _descriptionFontSize = 14.0;

  final Widget? title;
  final Widget? leading;
  final Widget? description;
  final bool enabled;
  final List<SettingsOption>? selectOptions;
  final String? selectValue;
  final void Function(String?)? onSelectChanged;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final selectedOption = selectOptions?.cast<SettingsOption?>().firstWhere(
          (o) => o?.value == selectValue,
          orElse: () => null,
        );

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _showSelectDialog(context, colorScheme) : null,
          highlightColor: theme.themeData.tileHighlightColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: 12.0,
            ),
            child: Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
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
                const SizedBox(width: _trailingGap),
                Text(
                  selectedOption?.label ?? '',
                  style: TextStyle(
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: _titleFontSize,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectDialog(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...?selectOptions?.map(
              (option) => ListTile(
                leading: option.icon,
                title: Text(option.label),
                trailing: option.value == selectValue
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelectChanged?.call(option.value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
