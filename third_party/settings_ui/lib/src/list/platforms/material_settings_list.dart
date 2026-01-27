import 'package:flutter/material.dart';
import 'package:settings_ui/src/list/abstract_settings_list.dart';
import 'package:settings_ui/src/utils/platform_utils.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

class MaterialSettingsList extends AbstractSettingsList {
  const MaterialSettingsList({
    required super.sections,
    super.shrinkWrap,
    super.physics,
    super.platform,
    super.contentPadding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePlatform = platform ?? DevicePlatform.android;
    final themeData = SettingsThemeData.withContext(context, effectivePlatform);

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        color: themeData.settingsListBackground,
        width: constraints.maxWidth,
        alignment: Alignment.center,
        child: SettingsTheme(
          themeData: themeData,
          platform: effectivePlatform,
          child: ListView.builder(
            physics: physics,
            shrinkWrap: shrinkWrap,
            itemCount: sections.length,
            padding:
                contentPadding ?? _calculateDefaultPadding(constraints),
            itemBuilder: (BuildContext context, int index) {
              return sections[index];
            },
          ),
        ),
      ),
    );
  }

  EdgeInsets _calculateDefaultPadding(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    if (maxWidth > 810) {
      final padding = (maxWidth - 810) / 2;
      return EdgeInsets.symmetric(horizontal: padding);
    }
    return EdgeInsets.symmetric(vertical: 0);
  }
}
