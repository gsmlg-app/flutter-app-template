import 'package:flutter/cupertino.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:settings_ui/src/tiles/platforms/cupertino_settings_tile.dart';

/// Cupertino (iOS/macOS) settings section implementation.
///
/// Follows Apple Human Interface Guidelines for iOS Settings:
/// - Inset grouped style with 10pt corner radius
/// - 16pt horizontal margin
/// - Section header: 13pt uppercase, secondary label color
/// - Header padding: 8pt bottom, aligned with content
/// - Footer/description below section with 13pt text
///
/// See: https://developer.apple.com/design/human-interface-guidelines/lists
class CupertinoSettingsSection extends AbstractSettingsSection {
  const CupertinoSettingsSection({
    required super.tiles,
    super.margin,
    super.title,
    super.key,
  });

  // Apple HIG specifications
  static const double _horizontalMargin = 16.0;
  static const double _cornerRadius = 10.0;
  static const double _headerFontSize = 13.0;
  static const double _headerBottomPadding = 6.0;
  static const double _sectionTopPadding = 22.0;
  static const double _sectionBottomPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final secondaryLabelColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    // Check if last tile has description (affects bottom padding)
    final isLastNonDescriptive = tiles.last is SettingsTile &&
        (tiles.last as SettingsTile).description == null;

    return Padding(
      padding: margin ??
          EdgeInsets.only(
            top: textScaler.scale(_sectionTopPadding),
            bottom: isLastNonDescriptive
                ? textScaler.scale(_sectionBottomPadding + 12)
                : textScaler.scale(_sectionBottomPadding),
            left: _horizontalMargin,
            right: _horizontalMargin,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (iOS-style uppercase)
          if (title != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: _horizontalMargin + 2,
                bottom: textScaler.scale(_headerBottomPadding),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: theme.themeData.titleTextColor ?? secondaryLabelColor,
                  fontSize: _headerFontSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.08,
                ),
                child: title!,
              ),
            ),

          // Tile list with rounded container
          ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: buildTileList(),
          ),
        ],
      ),
    );
  }

  Widget buildTileList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: tiles.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        final tile = tiles[index];

        // Enable top radius for first tile or after a tile with description
        var enableTop = false;
        if (index == 0 ||
            (index > 0 &&
                tiles[index - 1] is SettingsTile &&
                (tiles[index - 1] as SettingsTile).description != null)) {
          enableTop = true;
        }

        // Enable bottom radius for last tile or tiles with description
        var enableBottom = false;
        if (index == tiles.length - 1 ||
            (tile is SettingsTile && tile.description != null)) {
          enableBottom = true;
        }

        return CupertinoSettingsTileAdditionalInfo(
          enableTopBorderRadius: enableTop,
          enableBottomBorderRadius: enableBottom,
          needToShowDivider: index != tiles.length - 1,
          child: tile,
        );
      },
    );
  }
}
