import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Fluent Design (Windows 11) select tile implementation.
///
/// Provides a dropdown selection with Windows 11 Fluent styling.
class FluentSelectTile extends StatelessWidget {
  const FluentSelectTile({
    required this.title,
    required this.enabled,
    this.leading,
    this.description,
    this.selectOptions,
    this.selectValue,
    this.onSelectChanged,
    super.key,
  });

  // Fluent Design specifications
  static const double _borderRadius = 4.0;
  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 14.0;
  static const double _iconContainerSize = 36.0;
  static const double _iconSize = 20.0;
  static const double _contentGap = 16.0;
  static const double _headerFontSize = 14.0;
  static const double _descriptionFontSize = 12.0;

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
    final brightness = Theme.of(context).brightness;

    final cardColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
        : colorScheme.surfaceContainerLowest;

    final hoverColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;

    final selectedOption = selectOptions?.cast<SettingsOption?>().firstWhere(
          (o) => o?.value == selectValue,
          orElse: () => null,
        );

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => _showSelectMenu(context, colorScheme) : null,
          hoverColor: hoverColor,
          highlightColor: theme.themeData.tileHighlightColor ?? hoverColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  _buildLeadingIcon(context, theme, colorScheme),
                  const SizedBox(width: _contentGap),
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
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                          fontSize: _headerFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title ?? const SizedBox.shrink(),
                      ),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: enabled
                                  ? theme.themeData.tileDescriptionTextColor ??
                                      colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.38),
                              fontSize: _descriptionFontSize,
                            ),
                            child: description!,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: _contentGap),
                // Dropdown button style
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedOption?.label ?? '',
                        style: TextStyle(
                          color: enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                          fontSize: _headerFontSize,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: enabled
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  void _showSelectMenu(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Material(
          color: colorScheme.surface,
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
      ),
    );
  }
}
