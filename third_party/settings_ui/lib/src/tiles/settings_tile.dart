import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/tiles/platforms/cupertino_settings_tile.dart';
import 'package:settings_ui/src/tiles/platforms/fluent_settings_tile.dart';
import 'package:settings_ui/src/tiles/platforms/material_settings_tile.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Compositor widget that creates platform-specific settings tiles.
///
/// This widget does not extend [AbstractSettingsTile] because it uses
/// named constructors with late final assignments. Instead, it delegates
/// to design system implementations:
/// - [MaterialSettingsTile] for Android, Linux, Web, Fuchsia
/// - [CupertinoSettingsTile] for iOS, macOS
/// - [FluentSettingsTile] for Windows
class SettingsTile extends StatelessWidget {
  SettingsTile({
    this.leading,
    this.trailing,
    this.value,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) {
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.simpleTile;
    // New tile properties - null for simple tile
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  SettingsTile.navigation({
    this.leading,
    this.trailing,
    this.value,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) {
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.navigationTile;
    // New tile properties
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  SettingsTile.switchTile({
    required this.initialValue,
    required this.onToggle,
    this.activeSwitchColor,
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    super.key,
  }) {
    value = null;
    checked = null;
    tileType = SettingsTileType.switchTile;
    // New tile properties
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  SettingsTile.checkTile({
    this.leading,
    this.trailing,
    this.value,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    this.checked,
    super.key,
  }) {
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    tileType = SettingsTileType.checkTile;
    // New tile properties
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // New tile constructors
  // ───────────────────────────────────────────────────────────────────────────

  /// Creates a single-line text input tile.
  SettingsTile.input({
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    String? inputValue,
    required void Function(String) onInputChanged,
    String? inputHint,
    TextInputType? inputKeyboardType,
    int? inputMaxLength,
    super.key,
  }) {
    value = null;
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.inputTile;
    // Input properties
    this.inputValue = inputValue;
    this.onInputChanged = onInputChanged;
    this.inputHint = inputHint;
    this.inputKeyboardType = inputKeyboardType;
    this.inputMaxLength = inputMaxLength;
    // Other new tile properties null
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  /// Creates a slider tile for numeric value selection.
  SettingsTile.slider({
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    required double sliderValue,
    required void Function(double) onSliderChanged,
    double sliderMin = 0,
    double sliderMax = 1,
    int? sliderDivisions,
    super.key,
  }) {
    value = null;
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.sliderTile;
    // Input properties null
    inputValue = null;
    this.onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    // Slider properties
    this.sliderValue = sliderValue;
    this.onSliderChanged = onSliderChanged;
    this.sliderMin = sliderMin;
    this.sliderMax = sliderMax;
    this.sliderDivisions = sliderDivisions;
    // Other new tile properties null
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  /// Creates a dropdown/picker tile for option selection.
  SettingsTile.select({
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    required List<SettingsOption> options,
    String? selectValue,
    required void Function(String?) onSelectChanged,
    super.key,
  }) {
    value = null;
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.selectTile;
    // Input properties null
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    // Select properties
    selectOptions = options;
    this.selectValue = selectValue;
    this.onSelectChanged = onSelectChanged;
    // Other new tile properties null
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  /// Creates a multi-line text input tile.
  SettingsTile.textarea({
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    String? textareaValue,
    required void Function(String) onTextareaChanged,
    String? textareaHint,
    int textareaMaxLines = 3,
    int? textareaMaxLength,
    super.key,
  }) {
    value = null;
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.textareaTile;
    // Input properties null
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    // Textarea properties
    this.textareaValue = textareaValue;
    this.onTextareaChanged = onTextareaChanged;
    this.textareaHint = textareaHint;
    this.textareaMaxLines = textareaMaxLines;
    this.textareaMaxLength = textareaMaxLength;
    // Other new tile properties null
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  /// Creates a radio group tile with single selection.
  SettingsTile.radioGroup({
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    required List<SettingsOption> options,
    String? radioValue,
    required void Function(String?) onRadioChanged,
    super.key,
  }) {
    value = null;
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.radioGroupTile;
    // Input properties null
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    // Radio properties
    radioOptions = options;
    this.radioValue = radioValue;
    this.onRadioChanged = onRadioChanged;
    // Other new tile properties null
    checkboxOptions = null;
    checkboxValues = null;
    onCheckboxChanged = null;
  }

  /// Creates a checkbox group tile with multiple selection.
  SettingsTile.checkboxGroup({
    this.leading,
    this.trailing,
    required this.title,
    this.description,
    this.onPressed,
    this.enabled = true,
    required List<SettingsOption> options,
    required Set<String> checkboxValues,
    required void Function(Set<String>) onCheckboxChanged,
    super.key,
  }) {
    value = null;
    onToggle = null;
    initialValue = null;
    activeSwitchColor = null;
    checked = null;
    tileType = SettingsTileType.checkboxGroupTile;
    // Input properties null
    inputValue = null;
    onInputChanged = null;
    inputHint = null;
    inputKeyboardType = null;
    inputMaxLength = null;
    sliderValue = null;
    onSliderChanged = null;
    sliderMin = 0;
    sliderMax = 1;
    sliderDivisions = null;
    selectOptions = null;
    selectValue = null;
    onSelectChanged = null;
    textareaValue = null;
    onTextareaChanged = null;
    textareaHint = null;
    textareaMaxLines = 3;
    textareaMaxLength = null;
    radioOptions = null;
    radioValue = null;
    onRadioChanged = null;
    // Checkbox properties
    checkboxOptions = options;
    this.checkboxValues = checkboxValues;
    this.onCheckboxChanged = onCheckboxChanged;
  }

  /// The widget at the beginning of the tile
  final Widget? leading;

  /// The Widget at the end of the tile
  final Widget? trailing;

  /// The widget at the center of the tile
  final Widget title;

  /// The widget at the bottom of the [title]
  final Widget? description;

  /// A function that is called by tap on a tile
  final void Function(BuildContext context)? onPressed;

  late final Color? activeSwitchColor;
  late final Widget? value;
  late final Function(bool value)? onToggle;
  late final SettingsTileType tileType;
  late final bool? initialValue;
  late final bool enabled;
  late final bool? checked;

  // New tile properties
  late final String? inputValue;
  late final void Function(String)? onInputChanged;
  late final String? inputHint;
  late final TextInputType? inputKeyboardType;
  late final int? inputMaxLength;

  late final double? sliderValue;
  late final void Function(double)? onSliderChanged;
  late final double sliderMin;
  late final double sliderMax;
  late final int? sliderDivisions;

  late final List<SettingsOption>? selectOptions;
  late final String? selectValue;
  late final void Function(String?)? onSelectChanged;

  late final String? textareaValue;
  late final void Function(String)? onTextareaChanged;
  late final String? textareaHint;
  late final int textareaMaxLines;
  late final int? textareaMaxLength;

  late final List<SettingsOption>? radioOptions;
  late final String? radioValue;
  late final void Function(String?)? onRadioChanged;

  late final List<SettingsOption>? checkboxOptions;
  late final Set<String>? checkboxValues;
  late final void Function(Set<String>)? onCheckboxChanged;

  Widget? addCheckedTrailing(BuildContext context) {
    if (checked != null) {
      return checked!
          ? const Icon(Icons.check, color: Colors.lightGreen)
          : const Icon(Icons.check, color: Colors.transparent);
    }
    return trailing;
  }

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);

    switch (theme.platform) {
      case DevicePlatform.android:
      case DevicePlatform.fuchsia:
      case DevicePlatform.linux:
      case DevicePlatform.web:
      case DevicePlatform.custom:
        return MaterialSettingsTile(
          description: description,
          onPressed: onPressed,
          onToggle: onToggle,
          tileType: tileType,
          value: value,
          leading: leading,
          title: title,
          enabled: enabled,
          activeSwitchColor: activeSwitchColor,
          initialValue: initialValue ?? false,
          trailing: addCheckedTrailing(context),
          // New tile properties
          inputValue: inputValue,
          onInputChanged: onInputChanged,
          inputHint: inputHint,
          inputKeyboardType: inputKeyboardType,
          inputMaxLength: inputMaxLength,
          sliderValue: sliderValue,
          onSliderChanged: onSliderChanged,
          sliderMin: sliderMin,
          sliderMax: sliderMax,
          sliderDivisions: sliderDivisions,
          selectOptions: selectOptions,
          selectValue: selectValue,
          onSelectChanged: onSelectChanged,
          textareaValue: textareaValue,
          onTextareaChanged: onTextareaChanged,
          textareaHint: textareaHint,
          textareaMaxLines: textareaMaxLines,
          textareaMaxLength: textareaMaxLength,
          radioOptions: radioOptions,
          radioValue: radioValue,
          onRadioChanged: onRadioChanged,
          checkboxOptions: checkboxOptions,
          checkboxValues: checkboxValues,
          onCheckboxChanged: onCheckboxChanged,
        );
      case DevicePlatform.iOS:
      case DevicePlatform.macOS:
        return CupertinoSettingsTile(
          description: description,
          onPressed: onPressed,
          onToggle: onToggle,
          tileType: tileType,
          value: value,
          leading: leading,
          title: title,
          trailing: addCheckedTrailing(context),
          enabled: enabled,
          activeSwitchColor: activeSwitchColor,
          initialValue: initialValue ?? false,
          // New tile properties
          inputValue: inputValue,
          onInputChanged: onInputChanged,
          inputHint: inputHint,
          inputKeyboardType: inputKeyboardType,
          inputMaxLength: inputMaxLength,
          sliderValue: sliderValue,
          onSliderChanged: onSliderChanged,
          sliderMin: sliderMin,
          sliderMax: sliderMax,
          sliderDivisions: sliderDivisions,
          selectOptions: selectOptions,
          selectValue: selectValue,
          onSelectChanged: onSelectChanged,
          textareaValue: textareaValue,
          onTextareaChanged: onTextareaChanged,
          textareaHint: textareaHint,
          textareaMaxLines: textareaMaxLines,
          textareaMaxLength: textareaMaxLength,
          radioOptions: radioOptions,
          radioValue: radioValue,
          onRadioChanged: onRadioChanged,
          checkboxOptions: checkboxOptions,
          checkboxValues: checkboxValues,
          onCheckboxChanged: onCheckboxChanged,
        );
      case DevicePlatform.windows:
        return FluentSettingsTile(
          description: description,
          onPressed: onPressed,
          onToggle: onToggle,
          tileType: tileType,
          value: value,
          leading: leading,
          title: title,
          enabled: enabled,
          trailing: addCheckedTrailing(context),
          activeSwitchColor: activeSwitchColor,
          initialValue: initialValue ?? false,
          // New tile properties
          inputValue: inputValue,
          onInputChanged: onInputChanged,
          inputHint: inputHint,
          inputKeyboardType: inputKeyboardType,
          inputMaxLength: inputMaxLength,
          sliderValue: sliderValue,
          onSliderChanged: onSliderChanged,
          sliderMin: sliderMin,
          sliderMax: sliderMax,
          sliderDivisions: sliderDivisions,
          selectOptions: selectOptions,
          selectValue: selectValue,
          onSelectChanged: onSelectChanged,
          textareaValue: textareaValue,
          onTextareaChanged: onTextareaChanged,
          textareaHint: textareaHint,
          textareaMaxLines: textareaMaxLines,
          textareaMaxLength: textareaMaxLength,
          radioOptions: radioOptions,
          radioValue: radioValue,
          onRadioChanged: onRadioChanged,
          checkboxOptions: checkboxOptions,
          checkboxValues: checkboxValues,
          onCheckboxChanged: onCheckboxChanged,
        );
    }
  }
}
