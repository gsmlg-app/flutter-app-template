import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class IOSSettingsTile extends StatefulWidget {
  const IOSSettingsTile({
    required this.tileType,
    required this.leading,
    required this.title,
    required this.description,
    required this.onPressed,
    required this.onToggle,
    required this.value,
    required this.initialValue,
    required this.activeSwitchColor,
    required this.enabled,
    required this.trailing,
    super.key,
  });

  final SettingsTileType tileType;
  final Widget? leading;
  final Widget? title;
  final Widget? description;
  final Function(BuildContext context)? onPressed;
  final Function(bool value)? onToggle;
  final Widget? value;
  final bool? initialValue;
  final bool enabled;
  final Color? activeSwitchColor;
  final Widget? trailing;

  @override
  State<IOSSettingsTile> createState() => _IOSSettingsTileState();
}

class _IOSSettingsTileState extends State<IOSSettingsTile> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final additionalInfo = IOSSettingsTileAdditionalInfo.of(context);
    final theme = SettingsTheme.of(context);

    return IgnorePointer(
      ignoring: !widget.enabled,
      child: Column(
        children: [
          buildTitle(
            context: context,
            theme: theme,
            additionalInfo: additionalInfo,
          ),
          if (widget.description != null)
            buildDescription(
              context: context,
              theme: theme,
              additionalInfo: additionalInfo,
            ),
        ],
      ),
    );
  }

  Widget buildTitle({
    required BuildContext context,
    required SettingsTheme theme,
    required IOSSettingsTileAdditionalInfo additionalInfo,
  }) {
    Widget content = buildTileContent(context, theme, additionalInfo);
    if (!Platform.isIOS) {
      content = Material(
        color: Colors.transparent,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: additionalInfo.enableTopBorderRadius
            ? Radius.circular(12)
            : Radius.zero,
        bottom: additionalInfo.enableBottomBorderRadius
            ? Radius.circular(12)
            : Radius.zero,
      ),
      child: content,
    );
  }

  Widget buildDescription({
    required BuildContext context,
    required SettingsTheme theme,
    required IOSSettingsTileAdditionalInfo additionalInfo,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: textScaler.scale(8),
        bottom: additionalInfo.needToShowDivider ? 24 : textScaler.scale(8),
      ),
      decoration: BoxDecoration(
        color: theme.themeData.settingsListBackground,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: theme.themeData.titleTextColor,
          fontSize: 13,
        ),
        child: widget.description!,
      ),
    );
  }

  Widget buildTrailing({
    required BuildContext context,
    required SettingsTheme theme,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;
    return switch (widget.tileType) {
      SettingsTileType.switchTile => CupertinoSwitch(
          value: widget.initialValue ?? true,
          onChanged: widget.onToggle,
          activeTrackColor: widget.enabled
              ? widget.activeSwitchColor
              : theme.themeData.inactiveTitleColor,
        ),
      SettingsTileType.navigationTile => widget.value != null
          ? DefaultTextStyle(
              style: TextStyle(
                color: widget.enabled
                    ? theme.themeData.trailingTextColor
                    : theme.themeData.inactiveTitleColor,
                fontSize: 17,
              ),
              child: widget.value!,
            )
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
              child: IconTheme(
                data: IconTheme.of(context)
                    .copyWith(color: theme.themeData.leadingIconsColor),
                child: Icon(
                  CupertinoIcons.chevron_forward,
                  size: textScaler.scale(18),
                ),
              ),
            ),
      _ => widget.trailing ?? const SizedBox(),
    };
  }

  void changePressState({bool isPressed = false}) {
    if (mounted) {
      setState(() {
        this.isPressed = isPressed;
      });
    }
  }

  Widget buildTileContent(
    BuildContext context,
    SettingsTheme theme,
    IOSSettingsTileAdditionalInfo additionalInfo,
  ) {
    final textScaler = MediaQuery.of(context).textScaler;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onPressed == null
          ? null
          : () {
              changePressState(isPressed: true);

              widget.onPressed!.call(context);

              Future.delayed(
                Duration(milliseconds: 100),
                () => changePressState(isPressed: false),
              );
            },
      onTapDown: (_) =>
          widget.onPressed == null ? null : changePressState(isPressed: true),
      onTapUp: (_) =>
          widget.onPressed == null ? null : changePressState(isPressed: false),
      onTapCancel: () =>
          widget.onPressed == null ? null : changePressState(isPressed: false),
      child: Container(
        color: isPressed
            ? theme.themeData.tileHighlightColor
            : theme.themeData.settingsSectionBackground,
        padding: EdgeInsetsDirectional.only(start: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.leading != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12.0),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: widget.enabled
                        ? theme.themeData.leadingIconsColor
                        : theme.themeData.inactiveTitleColor,
                  ),
                  child: widget.leading!,
                ),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          padding: EdgeInsetsDirectional.only(
                            top: textScaler.scale(12.5),
                            bottom: textScaler.scale(12.5),
                          ),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: widget.enabled
                                  ? theme.themeData.settingsTileTextColor
                                  : theme.themeData.inactiveTitleColor,
                              fontSize: 16,
                            ),
                            child: widget.title!,
                          ),
                        ),
                        SizedBox(
                            width: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.fontSize),
                        const Spacer(),
                        Expanded(
                            child: Container(
                          padding: EdgeInsetsDirectional.only(
                            top: textScaler.scale(12.5),
                            bottom: textScaler.scale(12.5),
                          ),
                          alignment: Alignment.topRight,
                          child: buildTrailing(context: context, theme: theme),
                        )),
                      ],
                    ),
                  ),
                  if (widget.description == null &&
                      additionalInfo.needToShowDivider)
                    Divider(
                      height: 0,
                      thickness: 0.7,
                      color: theme.themeData.dividerColor,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IOSSettingsTileAdditionalInfo extends InheritedWidget {
  final bool needToShowDivider;
  final bool enableTopBorderRadius;
  final bool enableBottomBorderRadius;

  IOSSettingsTileAdditionalInfo({
    required this.needToShowDivider,
    required this.enableTopBorderRadius,
    required this.enableBottomBorderRadius,
    required super.child,
  });

  @override
  bool updateShouldNotify(IOSSettingsTileAdditionalInfo oldWidget) => true;

  static IOSSettingsTileAdditionalInfo of(BuildContext context) {
    final IOSSettingsTileAdditionalInfo? result = context
        .dependOnInheritedWidgetOfExactType<IOSSettingsTileAdditionalInfo>();
    // assert(result != null, 'No IOSSettingsTileAdditionalInfo found in context');
    return result ??
        IOSSettingsTileAdditionalInfo(
          needToShowDivider: true,
          enableBottomBorderRadius: true,
          enableTopBorderRadius: true,
          child: SizedBox(),
        );
  }
}
