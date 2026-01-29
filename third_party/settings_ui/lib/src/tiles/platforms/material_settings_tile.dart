import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/tiles/checkbox_group/material_checkbox_group_tile.dart';
import 'package:settings_ui/src/tiles/input/material_input_tile.dart';
import 'package:settings_ui/src/tiles/radio_group/material_radio_group_tile.dart';
import 'package:settings_ui/src/tiles/select/material_select_tile.dart';
import 'package:settings_ui/src/tiles/slider/material_slider_tile.dart';
import 'package:settings_ui/src/tiles/textarea/material_textarea_tile.dart';
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
    // Delegate to specialized standalone tile widgets
    switch (tileType) {
      case SettingsTileType.inputTile:
        return MaterialInputTile(
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
        return MaterialSliderTile(
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
        return MaterialSelectTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          selectOptions: selectOptions,
          selectValue: selectValue,
          onSelectChanged: onSelectChanged,
        );
      case SettingsTileType.textareaTile:
        return MaterialTextareaTile(
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
        return MaterialRadioGroupTile(
          title: title,
          leading: leading,
          description: description,
          enabled: enabled,
          radioOptions: radioOptions,
          radioValue: radioValue,
          onRadioChanged: onRadioChanged,
        );
      case SettingsTileType.checkboxGroupTile:
        return MaterialCheckboxGroupTile(
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
