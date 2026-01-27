import 'package:flutter/material.dart';
import 'package:settings_ui/src/sections/abstract_settings_section.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';

/// Abstract base class for settings lists.
///
/// Platform-specific implementations (Android, iOS, Web) extend this class
/// and implement the [build] method with platform-appropriate styling.
abstract class AbstractSettingsList extends StatelessWidget {
  const AbstractSettingsList({
    required this.sections,
    this.shrinkWrap = false,
    this.physics,
    this.platform,
    this.contentPadding,
    super.key,
  });

  /// The list of settings sections to display.
  final List<AbstractSettingsSection> sections;

  /// Whether the list should shrink-wrap its contents.
  final bool shrinkWrap;

  /// The scroll physics for the list.
  final ScrollPhysics? physics;

  /// The platform to use for styling. If null, auto-detected.
  final DevicePlatform? platform;

  /// Custom padding for the list content.
  final EdgeInsetsGeometry? contentPadding;
}
