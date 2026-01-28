import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Material Design 3 settings tile implementation.
///
/// Follows M3 List specifications:
/// - Single-line height: 56dp (with leading icon)
/// - Two-line height: 72dp
/// - Horizontal padding: 16dp
/// - Leading icon area: 56dp (16dp padding + 24dp icon + 16dp gap)
/// - Title: 16sp bodyLarge
/// - Description: 14sp bodyMedium
/// - Touch target: minimum 48dp
///
/// See: https://m3.material.io/components/lists/specs
class MaterialSettingsTile extends AbstractSettingsTile {
  const MaterialSettingsTile({
    required super.tileType,
    required super.title,
    super.leading,
    super.description,
    super.onPressed,
    super.onToggle,
    super.value,
    super.initialValue,
    super.activeSwitchColor,
    super.enabled,
    super.trailing,
    super.key,
  });

  // M3 specifications
  static const double _horizontalPadding = 16.0;
  static const double _leadingIconSize = 24.0;
  static const double _leadingGap = 16.0;
  static const double _trailingGap = 16.0;
  static const double _singleLineHeight = 56.0;
  static const double _twoLineHeight = 72.0;
  static const double _titleFontSize = 16.0;
  static const double _descriptionFontSize = 14.0;

  bool get _hasTwoLines => value != null || description != null;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final isInteractive = tileType == SettingsTileType.switchTile
        ? onToggle != null || onPressed != null
        : onPressed != null;

    final minHeight = _hasTwoLines ? _twoLineHeight : _singleLineHeight;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive
              ? () {
                  if (tileType == SettingsTileType.switchTile) {
                    onToggle?.call(!(initialValue ?? false));
                  } else {
                    onPressed?.call(context);
                  }
                }
              : null,
          highlightColor: theme.themeData.tileHighlightColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              child: Row(
                children: [
                  // Leading icon
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

                  // Content (title + description/value)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: _hasTwoLines ? 12.0 : 8.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          DefaultTextStyle(
                            style: TextStyle(
                              color: enabled
                                  ? theme.themeData.settingsTileTextColor ??
                                      colorScheme.onSurface
                                  : theme.themeData.inactiveTitleColor ??
                                      colorScheme.onSurface
                                          .withValues(alpha: 0.38),
                              fontSize: _titleFontSize,
                              fontWeight: FontWeight.w400,
                            ),
                            child: title ?? const SizedBox.shrink(),
                          ),

                          // Value or Description
                          if (value != null)
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
                                child: value!,
                              ),
                            )
                          else if (description != null)
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

                  // Trailing content
                  if (tileType == SettingsTileType.switchTile) ...[
                    if (trailing != null) ...[
                      trailing!,
                      const SizedBox(width: 8),
                    ],
                    Switch(
                      value: initialValue ?? false,
                      onChanged: enabled ? onToggle : null,
                      activeTrackColor: activeSwitchColor ?? colorScheme.primary,
                    ),
                  ] else if (trailing != null) ...[
                    const SizedBox(width: _trailingGap),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
