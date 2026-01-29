import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/src/tiles/platforms/cupertino_settings_tile.dart';
import 'package:settings_ui/src/utils/settings_option.dart';
import 'package:settings_ui/src/utils/settings_theme.dart';

/// Cupertino (iOS/macOS) select tile implementation.
///
/// Provides a selection picker with iOS/macOS styling using CupertinoActionSheet.
class CupertinoSelectTile extends StatelessWidget {
  const CupertinoSelectTile({
    required this.title,
    required this.enabled,
    required this.additionalInfo,
    this.leading,
    this.description,
    this.selectOptions,
    this.selectValue,
    this.onSelectChanged,
    super.key,
  });

  // Apple HIG specifications
  static const double _horizontalPadding = 16.0;
  static const double _leadingIconSize = 29.0;
  static const double _leadingGap = 12.0;
  static const double _titleFontSize = 17.0;
  static const double _secondaryFontSize = 15.0;
  static const double _descriptionFontSize = 13.0;
  static const double _chevronSize = 14.0;
  static const double _cornerRadius = 10.0;
  static const double _minRowHeight = 44.0;

  final Widget? title;
  final Widget? leading;
  final Widget? description;
  final bool enabled;
  final CupertinoSettingsTileAdditionalInfo additionalInfo;
  final List<SettingsOption>? selectOptions;
  final String? selectValue;
  final void Function(String?)? onSelectChanged;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    final selectedOption = selectOptions?.cast<SettingsOption?>().firstWhere(
          (o) => o?.value == selectValue,
          orElse: () => null,
        );

    Widget content = GestureDetector(
      onTap: enabled ? () => _showCupertinoSelectPicker(context) : null,
      child: Container(
        constraints: BoxConstraints(
          minHeight: textScaler.scale(_minRowHeight),
        ),
        color: theme.themeData.settingsSectionBackground ??
            CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context),
        padding: const EdgeInsetsDirectional.only(
          start: _horizontalPadding,
          end: _horizontalPadding,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(
                width: _leadingIconSize,
                height: _leadingIconSize,
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: _leadingIconSize,
                    color: enabled
                        ? theme.themeData.leadingIconsColor
                        : theme.themeData.inactiveTitleColor ??
                            secondaryLabelColor,
                  ),
                  child: Center(child: leading!),
                ),
              ),
              const SizedBox(width: _leadingGap),
            ],
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: enabled
                      ? theme.themeData.settingsTileTextColor ?? labelColor
                      : theme.themeData.inactiveTitleColor ?? secondaryLabelColor,
                  fontSize: _titleFontSize,
                  letterSpacing: -0.4,
                ),
                child: title ?? const SizedBox.shrink(),
              ),
            ),
            Text(
              selectedOption?.label ?? '',
              style: TextStyle(
                color: enabled
                    ? CupertinoColors.activeBlue.resolveFrom(context)
                    : secondaryLabelColor,
                fontSize: _secondaryFontSize,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_forward,
              size: textScaler.scale(_chevronSize),
              color: enabled
                  ? secondaryLabelColor
                  : theme.themeData.inactiveTitleColor,
            ),
          ],
        ),
      ),
    );

    if (!Platform.isIOS) {
      content = Material(color: Colors.transparent, child: content);
    }

    return IgnorePointer(
      ignoring: !enabled,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: additionalInfo.enableTopBorderRadius
              ? const Radius.circular(_cornerRadius)
              : Radius.zero,
          bottom: additionalInfo.enableBottomBorderRadius
              ? const Radius.circular(_cornerRadius)
              : Radius.zero,
        ),
        child: Column(
          children: [
            content,
            if (description != null) _buildDescription(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, SettingsTheme theme) {
    final textScaler = MediaQuery.of(context).textScaler;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: _horizontalPadding + 2,
        right: _horizontalPadding + 2,
        top: textScaler.scale(6),
        bottom: additionalInfo.needToShowDivider ? 20 : textScaler.scale(6),
      ),
      decoration: BoxDecoration(color: theme.themeData.settingsListBackground),
      child: DefaultTextStyle(
        style: TextStyle(
          color: theme.themeData.titleTextColor ??
              CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: _descriptionFontSize,
        ),
        child: description!,
      ),
    );
  }

  void _showCupertinoSelectPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: selectOptions
                ?.map((option) {
                  final isSelected = option.value == selectValue;
                  return CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      onSelectChanged?.call(option.value);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (option.icon != null) ...[
                          option.icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(option.label),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoColors.activeBlue.resolveFrom(context),
                          ),
                        ],
                      ],
                    ),
                  );
                })
                .toList() ??
            [],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
