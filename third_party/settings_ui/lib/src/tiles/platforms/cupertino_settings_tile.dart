import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/abstract_settings_tile.dart';
import 'package:settings_ui/src/tiles/checkbox_group/cupertino_checkbox_group_tile.dart';
import 'package:settings_ui/src/tiles/input/cupertino_input_tile.dart';
import 'package:settings_ui/src/tiles/radio_group/cupertino_radio_group_tile.dart';
import 'package:settings_ui/src/tiles/select/cupertino_select_tile.dart';
import 'package:settings_ui/src/tiles/slider/cupertino_slider_tile.dart';
import 'package:settings_ui/src/tiles/textarea/cupertino_textarea_tile.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Cupertino (iOS/macOS) settings tile implementation.
///
/// Follows Apple Human Interface Guidelines for iOS Settings:
/// - Minimum row height: 44pt (touch target)
/// - Horizontal padding: 16pt (leading) + 16pt (trailing)
/// - Corner radius: 10pt for inset grouped style
/// - Title: SF Pro Text 17pt (-0.4 letter spacing)
/// - Secondary text: SF Pro Text 15pt, secondary label color
/// - Uses CupertinoSwitch for toggle tiles
/// - Chevron (14pt) for navigation tiles
///
/// See: https://developer.apple.com/design/human-interface-guidelines/lists
class CupertinoSettingsTile extends StatefulWidget {
  const CupertinoSettingsTile({
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
    // New tile properties
    this.inputValue,
    this.onInputChanged,
    this.inputHint,
    this.inputKeyboardType,
    this.inputMaxLength,
    this.sliderValue,
    this.onSliderChanged,
    this.sliderMin = 0,
    this.sliderMax = 1,
    this.sliderDivisions,
    this.selectOptions,
    this.selectValue,
    this.onSelectChanged,
    this.textareaValue,
    this.onTextareaChanged,
    this.textareaHint,
    this.textareaMaxLines = 3,
    this.textareaMaxLength,
    this.radioOptions,
    this.radioValue,
    this.onRadioChanged,
    this.checkboxOptions,
    this.checkboxValues,
    this.onCheckboxChanged,
    super.key,
  });

  // Apple HIG specifications
  static const double _minRowHeight = 44.0;
  static const double _horizontalPadding = 16.0;
  static const double _cornerRadius = 10.0;
  static const double _leadingIconSize = 29.0;
  static const double _leadingGap = 12.0;
  static const double _titleFontSize = 17.0;
  static const double _secondaryFontSize = 15.0;
  static const double _descriptionFontSize = 13.0;
  static const double _chevronSize = 14.0;

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

  // New tile properties
  final String? inputValue;
  final void Function(String)? onInputChanged;
  final String? inputHint;
  final TextInputType? inputKeyboardType;
  final int? inputMaxLength;

  final double? sliderValue;
  final void Function(double)? onSliderChanged;
  final double sliderMin;
  final double sliderMax;
  final int? sliderDivisions;

  final List<SettingsOption>? selectOptions;
  final String? selectValue;
  final void Function(String?)? onSelectChanged;

  final String? textareaValue;
  final void Function(String)? onTextareaChanged;
  final String? textareaHint;
  final int textareaMaxLines;
  final int? textareaMaxLength;

  final List<SettingsOption>? radioOptions;
  final String? radioValue;
  final void Function(String?)? onRadioChanged;

  final List<SettingsOption>? checkboxOptions;
  final Set<String>? checkboxValues;
  final void Function(Set<String>)? onCheckboxChanged;

  @override
  State<CupertinoSettingsTile> createState() => _CupertinoSettingsTileState();
}

class _CupertinoSettingsTileState extends State<CupertinoSettingsTile> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final additionalInfo = CupertinoSettingsTileAdditionalInfo.of(context);
    final theme = SettingsTheme.of(context);

    // Delegate to specialized standalone tile widgets
    switch (widget.tileType) {
      case SettingsTileType.inputTile:
        return CupertinoInputTile(
          title: widget.title,
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          additionalInfo: additionalInfo,
          inputValue: widget.inputValue,
          onInputChanged: widget.onInputChanged,
          inputHint: widget.inputHint,
          inputKeyboardType: widget.inputKeyboardType,
          inputMaxLength: widget.inputMaxLength,
        );
      case SettingsTileType.sliderTile:
        return CupertinoSliderTile(
          title: widget.title,
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          additionalInfo: additionalInfo,
          sliderValue: widget.sliderValue,
          onSliderChanged: widget.onSliderChanged,
          sliderMin: widget.sliderMin,
          sliderMax: widget.sliderMax,
          sliderDivisions: widget.sliderDivisions,
        );
      case SettingsTileType.selectTile:
        return CupertinoSelectTile(
          title: widget.title,
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          additionalInfo: additionalInfo,
          selectOptions: widget.selectOptions,
          selectValue: widget.selectValue,
          onSelectChanged: widget.onSelectChanged,
        );
      case SettingsTileType.textareaTile:
        return CupertinoTextareaTile(
          title: widget.title,
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          additionalInfo: additionalInfo,
          textareaValue: widget.textareaValue,
          onTextareaChanged: widget.onTextareaChanged,
          textareaHint: widget.textareaHint,
          textareaMaxLines: widget.textareaMaxLines,
          textareaMaxLength: widget.textareaMaxLength,
        );
      case SettingsTileType.radioGroupTile:
        return CupertinoRadioGroupTile(
          title: widget.title,
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          additionalInfo: additionalInfo,
          radioOptions: widget.radioOptions,
          radioValue: widget.radioValue,
          onRadioChanged: widget.onRadioChanged,
        );
      case SettingsTileType.checkboxGroupTile:
        return CupertinoCheckboxGroupTile(
          title: widget.title,
          leading: widget.leading,
          description: widget.description,
          enabled: widget.enabled,
          additionalInfo: additionalInfo,
          checkboxOptions: widget.checkboxOptions,
          checkboxValues: widget.checkboxValues,
          onCheckboxChanged: widget.onCheckboxChanged,
        );
      default:
        return _buildStandardTile(context, theme, additionalInfo);
    }
  }

  Widget _buildStandardTile(
    BuildContext context,
    SettingsTheme theme,
    CupertinoSettingsTileAdditionalInfo additionalInfo,
  ) {
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
    required CupertinoSettingsTileAdditionalInfo additionalInfo,
  }) {
    Widget content = buildTileContent(context, theme, additionalInfo);
    if (!Platform.isIOS) {
      content = Material(color: Colors.transparent, child: content);
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: additionalInfo.enableTopBorderRadius
            ? Radius.circular(CupertinoSettingsTile._cornerRadius)
            : Radius.zero,
        bottom: additionalInfo.enableBottomBorderRadius
            ? Radius.circular(CupertinoSettingsTile._cornerRadius)
            : Radius.zero,
      ),
      child: content,
    );
  }

  Widget buildDescription({
    required BuildContext context,
    required SettingsTheme theme,
    required CupertinoSettingsTileAdditionalInfo additionalInfo,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: CupertinoSettingsTile._horizontalPadding + 2,
        right: CupertinoSettingsTile._horizontalPadding + 2,
        top: textScaler.scale(6),
        bottom: additionalInfo.needToShowDivider ? 20 : textScaler.scale(6),
      ),
      decoration: BoxDecoration(color: theme.themeData.settingsListBackground),
      child: DefaultTextStyle(
        style: TextStyle(
          color: theme.themeData.titleTextColor ??
              CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: CupertinoSettingsTile._descriptionFontSize,
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
    final secondaryLabelColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    return switch (widget.tileType) {
      SettingsTileType.switchTile => CupertinoSwitch(
        value: widget.initialValue ?? true,
        onChanged: widget.enabled ? widget.onToggle : null,
        activeTrackColor: widget.activeSwitchColor,
      ),
      SettingsTileType.navigationTile => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.value != null)
            DefaultTextStyle(
              style: TextStyle(
                color: widget.enabled
                    ? theme.themeData.trailingTextColor ?? secondaryLabelColor
                    : theme.themeData.inactiveTitleColor,
                fontSize: CupertinoSettingsTile._secondaryFontSize,
              ),
              child: widget.value!,
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Icon(
              CupertinoIcons.chevron_forward,
              size: textScaler.scale(CupertinoSettingsTile._chevronSize),
              color: widget.enabled
                  ? theme.themeData.leadingIconsColor ?? secondaryLabelColor
                  : theme.themeData.inactiveTitleColor,
            ),
          ),
        ],
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
    CupertinoSettingsTileAdditionalInfo additionalInfo,
  ) {
    final textScaler = MediaQuery.of(context).textScaler;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    final isInteractive = widget.tileType == SettingsTileType.switchTile
        ? widget.onToggle != null || widget.onPressed != null
        : widget.onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: !isInteractive
          ? null
          : () {
              changePressState(isPressed: true);
              if (widget.tileType == SettingsTileType.switchTile) {
                widget.onToggle?.call(!(widget.initialValue ?? false));
              } else {
                widget.onPressed?.call(context);
              }
              Future.delayed(
                Duration(milliseconds: 100),
                () => changePressState(isPressed: false),
              );
            },
      onTapDown: (_) =>
          isInteractive ? changePressState(isPressed: true) : null,
      onTapUp: (_) =>
          isInteractive ? changePressState(isPressed: false) : null,
      onTapCancel: () =>
          isInteractive ? changePressState(isPressed: false) : null,
      child: Container(
        constraints: BoxConstraints(
          minHeight: textScaler.scale(CupertinoSettingsTile._minRowHeight),
        ),
        color: isPressed
            ? theme.themeData.tileHighlightColor ??
                CupertinoColors.systemGrey4.resolveFrom(context)
            : theme.themeData.settingsSectionBackground ??
                CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
        padding: EdgeInsetsDirectional.only(
          start: CupertinoSettingsTile._horizontalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading icon
            if (widget.leading != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: CupertinoSettingsTile._leadingGap,
                ),
                child: SizedBox(
                  width: CupertinoSettingsTile._leadingIconSize,
                  height: CupertinoSettingsTile._leadingIconSize,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: CupertinoSettingsTile._leadingIconSize,
                      color: widget.enabled
                          ? theme.themeData.leadingIconsColor
                          : theme.themeData.inactiveTitleColor ??
                              secondaryLabelColor,
                    ),
                    child: Center(child: widget.leading!),
                  ),
                ),
              ),

            // Content area
            Expanded(
              child: Container(
                padding: EdgeInsetsDirectional.only(
                  end: CupertinoSettingsTile._horizontalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main row: title + trailing
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            textScaler.scale(CupertinoSettingsTile._minRowHeight),
                      ),
                      child: Row(
                        children: [
                          // Title
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                top: textScaler.scale(11),
                                bottom: textScaler.scale(11),
                              ),
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  color: widget.enabled
                                      ? theme.themeData.settingsTileTextColor ??
                                          labelColor
                                      : theme.themeData.inactiveTitleColor ??
                                          secondaryLabelColor,
                                  fontSize: CupertinoSettingsTile._titleFontSize,
                                  letterSpacing: -0.4,
                                ),
                                child: widget.title ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),

                          // Trailing
                          buildTrailing(context: context, theme: theme),
                        ],
                      ),
                    ),

                    // Divider (iOS-style, inset from leading edge)
                    if (widget.description == null &&
                        additionalInfo.needToShowDivider)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: theme.themeData.dividerColor ??
                            CupertinoColors.separator.resolveFrom(context),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class CupertinoSettingsTileAdditionalInfo extends InheritedWidget {
  final bool needToShowDivider;
  final bool enableTopBorderRadius;
  final bool enableBottomBorderRadius;

  CupertinoSettingsTileAdditionalInfo({
    required this.needToShowDivider,
    required this.enableTopBorderRadius,
    required this.enableBottomBorderRadius,
    required super.child,
  });

  @override
  bool updateShouldNotify(CupertinoSettingsTileAdditionalInfo oldWidget) => true;

  static CupertinoSettingsTileAdditionalInfo of(BuildContext context) {
    final CupertinoSettingsTileAdditionalInfo? result = context
        .dependOnInheritedWidgetOfExactType<CupertinoSettingsTileAdditionalInfo>();
    // assert(result != null, 'No CupertinoSettingsTileAdditionalInfo found in context');
    return result ??
        CupertinoSettingsTileAdditionalInfo(
          needToShowDivider: true,
          enableBottomBorderRadius: true,
          enableTopBorderRadius: true,
          child: SizedBox(),
        );
  }
}
