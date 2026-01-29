import 'package:flutter/material.dart';
import 'package:settings_ui/src/utils/settings_option.dart';

/// Enum representing the type of settings tile.
enum SettingsTileType {
  simpleTile,
  switchTile,
  navigationTile,
  checkTile,
  // New tile types
  inputTile,
  sliderTile,
  selectTile,
  textareaTile,
  radioGroupTile,
  checkboxGroupTile,
}

/// Abstract base class for settings tiles.
///
/// Platform-specific implementations (Android, iOS, Web) extend this class
/// and implement the [build] method with platform-appropriate styling.
///
/// Note: [IOSSettingsTile] is a [StatefulWidget] (for press animation state)
/// and does not extend this class, but maintains the same constructor signature.
abstract class AbstractSettingsTile extends StatelessWidget {
  const AbstractSettingsTile({
    required this.title,
    required this.tileType,
    this.leading,
    this.trailing,
    this.description,
    this.value,
    this.onPressed,
    this.onToggle,
    this.initialValue,
    this.activeSwitchColor,
    this.enabled = true,
    // Input tile properties
    this.inputValue,
    this.onInputChanged,
    this.inputHint,
    this.inputKeyboardType,
    this.inputMaxLength,
    // Slider tile properties
    this.sliderValue,
    this.onSliderChanged,
    this.sliderMin = 0,
    this.sliderMax = 1,
    this.sliderDivisions,
    // Select tile properties
    this.selectOptions,
    this.selectValue,
    this.onSelectChanged,
    // Textarea tile properties
    this.textareaValue,
    this.onTextareaChanged,
    this.textareaHint,
    this.textareaMaxLines = 3,
    this.textareaMaxLength,
    // Radio group tile properties
    this.radioOptions,
    this.radioValue,
    this.onRadioChanged,
    // Checkbox group tile properties
    this.checkboxOptions,
    this.checkboxValues,
    this.onCheckboxChanged,
    super.key,
  });

  /// The widget at the beginning of the tile.
  final Widget? leading;

  /// The main title widget of the tile.
  final Widget? title;

  /// The widget at the bottom of the [title].
  final Widget? description;

  /// The widget at the end of the tile.
  final Widget? trailing;

  /// The value widget displayed below or next to the title.
  final Widget? value;

  /// The type of this tile (simple, switch, navigation, or check).
  final SettingsTileType tileType;

  /// Callback when the tile is pressed.
  final void Function(BuildContext context)? onPressed;

  /// Callback when the switch is toggled (for switch tiles).
  final void Function(bool value)? onToggle;

  /// Initial value for switch tiles.
  final bool? initialValue;

  /// Color for the active state of switch tiles.
  final Color? activeSwitchColor;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  // ─────────────────────────────────────────────────────────────────────────
  // Input tile properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Current text value for input tile.
  final String? inputValue;

  /// Callback when input text changes.
  final void Function(String)? onInputChanged;

  /// Placeholder text for input tile.
  final String? inputHint;

  /// Keyboard type for input tile.
  final TextInputType? inputKeyboardType;

  /// Maximum character length for input tile.
  final int? inputMaxLength;

  // ─────────────────────────────────────────────────────────────────────────
  // Slider tile properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Current value for slider tile.
  final double? sliderValue;

  /// Callback when slider value changes.
  final void Function(double)? onSliderChanged;

  /// Minimum value for slider tile.
  final double sliderMin;

  /// Maximum value for slider tile.
  final double sliderMax;

  /// Number of discrete divisions for slider tile.
  final int? sliderDivisions;

  // ─────────────────────────────────────────────────────────────────────────
  // Select tile properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Available options for select tile.
  final List<SettingsOption>? selectOptions;

  /// Currently selected value for select tile.
  final String? selectValue;

  /// Callback when selection changes.
  final void Function(String?)? onSelectChanged;

  // ─────────────────────────────────────────────────────────────────────────
  // Textarea tile properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Current text value for textarea tile.
  final String? textareaValue;

  /// Callback when textarea text changes.
  final void Function(String)? onTextareaChanged;

  /// Placeholder text for textarea tile.
  final String? textareaHint;

  /// Number of visible lines for textarea tile.
  final int textareaMaxLines;

  /// Maximum character length for textarea tile.
  final int? textareaMaxLength;

  // ─────────────────────────────────────────────────────────────────────────
  // Radio group tile properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Available options for radio group tile.
  final List<SettingsOption>? radioOptions;

  /// Currently selected value for radio group tile.
  final String? radioValue;

  /// Callback when radio selection changes.
  final void Function(String?)? onRadioChanged;

  // ─────────────────────────────────────────────────────────────────────────
  // Checkbox group tile properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Available options for checkbox group tile.
  final List<SettingsOption>? checkboxOptions;

  /// Currently selected values for checkbox group tile.
  final Set<String>? checkboxValues;

  /// Callback when checkbox selection changes.
  final void Function(Set<String>)? onCheckboxChanged;
}
