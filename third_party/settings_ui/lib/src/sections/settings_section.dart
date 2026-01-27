import 'package:flutter/material.dart';
import 'package:settings_ui/src/sections/abstract_settings_section.dart';
import 'package:settings_ui/src/sections/platforms/cupertino_settings_section.dart';
import 'package:settings_ui/src/sections/platforms/fluent_settings_section.dart';
import 'package:settings_ui/src/sections/platforms/material_settings_section.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Compositor widget that creates platform-specific settings sections.
///
/// Delegates to design system implementations:
/// - [MaterialSettingsSection] for Android, Linux, Web, Fuchsia
/// - [CupertinoSettingsSection] for iOS, macOS
/// - [FluentSettingsSection] for Windows
class SettingsSection extends AbstractSettingsSection {
  const SettingsSection({
    required super.tiles,
    super.margin,
    super.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);

    switch (theme.platform) {
      case DevicePlatform.android:
      case DevicePlatform.fuchsia:
      case DevicePlatform.linux:
      case DevicePlatform.web:
      case DevicePlatform.custom:
        return MaterialSettingsSection(
          title: title,
          tiles: tiles,
          margin: margin,
        );
      case DevicePlatform.iOS:
      case DevicePlatform.macOS:
        return CupertinoSettingsSection(
          title: title,
          tiles: tiles,
          margin: margin,
        );
      case DevicePlatform.windows:
        return FluentSettingsSection(
          title: title,
          tiles: tiles,
          margin: margin,
        );
    }
  }
}
