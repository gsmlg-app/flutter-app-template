import 'package:flutter/material.dart';

/// Enum representing the type of settings tile.
enum SettingsTileType { simpleTile, switchTile, navigationTile, checkTile }

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
}
