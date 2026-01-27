import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class FluentSettingsSection extends AbstractSettingsSection {
  const FluentSettingsSection({
    required super.tiles,
    super.margin,
    super.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionBody(context);
  }

  Widget buildSectionBody(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final textScaler = MediaQuery.of(context).textScaler;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              height: textScaler.scale(65),
              padding: EdgeInsetsDirectional.only(
                bottom: textScaler.scale(5),
                start: 6,
                top: textScaler.scale(40),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: theme.themeData.titleTextColor,
                  fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                ),
                child: title!,
              ),
            ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
            color: theme.themeData.settingsSectionBackground,
            child: buildTileList(),
          ),
        ],
      ),
    );
  }

  Widget buildTileList() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: tiles.length,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(height: 0, thickness: 1);
      },
    );
  }
}
