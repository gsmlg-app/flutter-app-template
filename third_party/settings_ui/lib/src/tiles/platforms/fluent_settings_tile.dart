import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/tiles/checkbox_group/fluent_checkbox_group_tile.dart';
import 'package:settings_ui/src/tiles/input/fluent_input_tile.dart';
import 'package:settings_ui/src/tiles/radio_group/fluent_radio_group_tile.dart';
import 'package:settings_ui/src/tiles/select/fluent_select_tile.dart';
import 'package:settings_ui/src/tiles/slider/fluent_slider_tile.dart';
import 'package:settings_ui/src/tiles/textarea/fluent_textarea_tile.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Fluent Design (Windows 11) settings tile implementation.
///
/// Follows Windows 11 SettingsCard specifications:
/// - Card-based layout with subtle elevation
/// - Rounded corners (4dp radius)
/// - Icon (36dp container) + Header + Description layout
/// - Content aligned right by default
/// - Hover/press states with subtle background change
///
/// See: https://learn.microsoft.com/en-us/dotnet/communitytoolkit/windows/settingscontrols/settingsexpander
class FluentSettingsTile extends AbstractSettingsTile {
  const FluentSettingsTile({
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
    // New tile properties
    super.inputValue,
    super.onInputChanged,
    super.inputHint,
    super.inputKeyboardType,
    super.inputMaxLength,
    super.sliderValue,
    super.onSliderChanged,
    super.sliderMin,
    super.sliderMax,
    super.sliderDivisions,
    super.selectOptions,
    super.selectValue,
    super.onSelectChanged,
    super.textareaValue,
    super.onTextareaChanged,
    super.textareaHint,
    super.textareaMaxLines,
    super.textareaMaxLength,
    super.radioOptions,
    super.radioValue,
    super.onRadioChanged,
    super.checkboxOptions,
    super.checkboxValues,
    super.onCheckboxChanged,
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

  @override
  Widget build(BuildContext context) {
    // Delegate to specialized standalone tile widgets
    switch (tileType) {
      case SettingsTileType.inputTile:
        return FluentInputTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          inputValue: inputValue,
          onInputChanged: onInputChanged,
          inputHint: inputHint,
          inputKeyboardType: inputKeyboardType,
          inputMaxLength: inputMaxLength,
        );
      case SettingsTileType.sliderTile:
        return FluentSliderTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          sliderValue: sliderValue,
          onSliderChanged: onSliderChanged,
          sliderMin: sliderMin,
          sliderMax: sliderMax,
          sliderDivisions: sliderDivisions,
        );
      case SettingsTileType.selectTile:
        return FluentSelectTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          selectOptions: selectOptions,
          selectValue: selectValue,
          onSelectChanged: onSelectChanged,
        );
      case SettingsTileType.textareaTile:
        return FluentTextareaTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          textareaValue: textareaValue,
          onTextareaChanged: onTextareaChanged,
          textareaHint: textareaHint,
          textareaMaxLines: textareaMaxLines,
          textareaMaxLength: textareaMaxLength,
        );
      case SettingsTileType.radioGroupTile:
        return FluentRadioGroupTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          radioOptions: radioOptions,
          radioValue: radioValue,
          onRadioChanged: onRadioChanged,
        );
      case SettingsTileType.checkboxGroupTile:
        return FluentCheckboxGroupTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          checkboxOptions: checkboxOptions,
          checkboxValues: checkboxValues,
          onCheckboxChanged: onCheckboxChanged,
        );
      default:
        return _buildStandardTile(context);
    }
  }

  /// Builds the standard tile layout (simple, switch, navigation, check).
  Widget _buildStandardTile(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final isInteractive = tileType == SettingsTileType.switchTile
        ? onToggle != null || onPressed != null
        : onPressed != null;

    // Fluent Design uses subtle surface colors
    final cardColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
        : colorScheme.surfaceContainerLowest;

    final hoverColor = brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        clipBehavior: Clip.antiAlias,
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
          hoverColor: hoverColor,
          highlightColor: theme.themeData.tileHighlightColor ?? hoverColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            child: Row(
              children: [
                // Leading icon in container
                if (leading != null) ...[
                  Container(
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
                            ? theme.themeData.leadingIconsColor ??
                                colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      child: Center(child: leading!),
                    ),
                  ),
                  const SizedBox(width: _contentGap),
                ],

                // Content (header + description)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header (title)
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

                      // Description
                      if (description != null || value != null)
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
                            child: value ?? description!,
                          ),
                        ),
                    ],
                  ),
                ),

                // Trailing content
                if (tileType == SettingsTileType.switchTile) ...[
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 12),
                  ],
                  Switch(
                    value: initialValue ?? false,
                    onChanged: enabled ? onToggle : null,
                    activeTrackColor: activeSwitchColor ?? colorScheme.primary,
                  ),
                ] else if (tileType == SettingsTileType.navigationTile) ...[
                  const SizedBox(width: _contentGap),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ] else if (trailing != null) ...[
                  const SizedBox(width: _contentGap),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}
