import 'package:flutter/material.dart';

/// Abstract base class for settings sections.
///
/// Platform-specific implementations (Android, iOS, Web) extend this class
/// and implement the [build] method with platform-appropriate styling.
abstract class AbstractSettingsSection extends StatelessWidget {
  const AbstractSettingsSection({
    required this.tiles,
    this.margin,
    this.title,
    super.key,
  });

  /// The list of tiles to display in this section.
  final List<Widget> tiles;

  /// Optional margin around the section.
  final EdgeInsetsDirectional? margin;

  /// Optional title widget displayed above the tiles.
  final Widget? title;
}
