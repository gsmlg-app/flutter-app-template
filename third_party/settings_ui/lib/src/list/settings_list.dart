import 'package:flutter/material.dart';
import 'package:settings_ui/src/list/abstract_settings_list.dart';
import 'package:settings_ui/src/list/platforms/cupertino_settings_list.dart';
import 'package:settings_ui/src/list/platforms/fluent_settings_list.dart';
import 'package:settings_ui/src/list/platforms/material_settings_list.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';

/// Compositor widget that creates platform-specific settings lists.
///
/// Delegates to design system implementations:
/// - [MaterialSettingsList] for Android, Linux, Web, Fuchsia
/// - [CupertinoSettingsList] for iOS, macOS
/// - [FluentSettingsList] for Windows
class SettingsList extends AbstractSettingsList {
  const SettingsList({
    required super.sections,
    super.shrinkWrap,
    super.physics,
    super.platform,
    super.contentPadding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePlatform = platform ?? DevicePlatform.detect();

    switch (effectivePlatform) {
      case DevicePlatform.android:
      case DevicePlatform.fuchsia:
      case DevicePlatform.linux:
      case DevicePlatform.web:
      case DevicePlatform.custom:
        return MaterialSettingsList(
          sections: sections,
          shrinkWrap: shrinkWrap,
          physics: physics,
          platform: effectivePlatform,
          contentPadding: contentPadding,
        );
      case DevicePlatform.iOS:
      case DevicePlatform.macOS:
        return CupertinoSettingsList(
          sections: sections,
          shrinkWrap: shrinkWrap,
          physics: physics,
          platform: effectivePlatform,
          contentPadding: contentPadding,
        );
      case DevicePlatform.windows:
        return FluentSettingsList(
          sections: sections,
          shrinkWrap: shrinkWrap,
          physics: physics,
          platform: effectivePlatform,
          contentPadding: contentPadding,
        );
    }
  }
}
