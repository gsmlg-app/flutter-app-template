import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

class FluentSettingsTile extends AbstractSettingsTile {
  const FluentSettingsTile({
    required super.tileType,
    required super.title,
    super.leading,
    super.description,
    super.onPressed,
    super.onToggle,
    super.value,
    super.initialValue,
    super.activeSwitchColor,
    super.enabled,
    super.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final textScaler = MediaQuery.of(context).textScaler;

    final cantShowAnimation = tileType == SettingsTileType.switchTile
        ? onToggle == null && onPressed == null
        : onPressed == null;

    return IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: cantShowAnimation
              ? null
              : () {
                  if (tileType == SettingsTileType.switchTile) {
                    onToggle?.call(!(initialValue ?? false));
                  } else {
                    onPressed?.call(context);
                  }
                },
          highlightColor: theme.themeData.tileHighlightColor,
          child: Container(
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 24),
                    child: IconTheme(
                      data: IconTheme.of(
                        context,
                      ).copyWith(color: theme.themeData.leadingIconsColor),
                      child: leading!,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 24,
                      end: 24,
                      bottom: textScaler.scale(19),
                      top: textScaler.scale(19),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: TextStyle(
                            color: theme.themeData.settingsTileTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          child: title ?? Container(),
                        ),
                        if (value != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: theme.themeData.tileDescriptionTextColor,
                              ),
                              child: value!,
                            ),
                          )
                        else if (description != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: theme.themeData.tileDescriptionTextColor,
                              ),
                              child: description!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // if (tileType == SettingsTileType.navigationTile)
                //   Padding(
                //     padding:
                //         const EdgeInsetsDirectional.only(start: 6, end: 15),
                //     child: IconTheme(
                //       data: IconTheme.of(context)
                //           .copyWith(color: theme.themeData.leadingIconsColor),
                //       child: Icon(
                //         CupertinoIcons.chevron_forward,
                //         size: 18 * scaleFactor,
                //       ),
                //     ),
                //   ),
                if (trailing != null && tileType == SettingsTileType.switchTile)
                  Row(
                    children: [
                      trailing!,
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Switch(
                          activeThumbColor:
                              activeSwitchColor ??
                              Color.fromRGBO(138, 180, 248, 1.0),
                          value: initialValue ?? false,
                          onChanged: onToggle,
                        ),
                      ),
                    ],
                  )
                else if (tileType == SettingsTileType.switchTile)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 8,
                    ),
                    child: Switch(
                      value: initialValue ?? false,
                      activeThumbColor:
                          activeSwitchColor ??
                          Color.fromRGBO(138, 180, 248, 1.0),
                      onChanged: onToggle,
                    ),
                  )
                else if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: trailing!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
