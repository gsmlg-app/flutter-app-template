import 'package:flutter/widgets.dart';

/// Represents an option for selection-based settings tiles.
///
/// Used by [SettingsTile.select], [SettingsTile.radioGroup],
/// and [SettingsTile.checkboxGroup] to define available choices.
class SettingsOption {
  /// Creates a settings option.
  ///
  /// [value] is the unique identifier used in callbacks.
  /// [label] is the user-visible text for this option.
  /// [icon] is an optional leading icon for the option.
  const SettingsOption({
    required this.value,
    required this.label,
    this.icon,
  });

  /// The unique value identifying this option.
  ///
  /// This is passed to callbacks when the option is selected.
  final String value;

  /// The display label for this option.
  final String label;

  /// Optional icon displayed alongside the label.
  final Widget? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
