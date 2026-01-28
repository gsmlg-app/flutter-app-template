import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

/// Fluent Design (Windows 11) settings section implementation.
///
/// Follows Windows 11 Settings app specifications:
/// - Section header: 14sp semibold, text-primary color
/// - 4dp vertical spacing between tiles (individual cards)
/// - No card wrapper around section (tiles are individual cards)
/// - Header padding: 24dp top (first section), 8dp bottom
///
/// Note: Unlike Material (flat) and Cupertino (grouped), Fluent Design
/// uses individual card-based tiles with spacing between them.
///
/// See: https://learn.microsoft.com/en-us/dotnet/communitytoolkit/windows/settingscontrols/settingsexpander
class FluentSettingsSection extends AbstractSettingsSection {
  const FluentSettingsSection({
    required super.tiles,
    super.margin,
    super.title,
    super.key,
  });

  // Fluent Design specifications
  static const double _headerFontSize = 14.0;
  static const double _headerTopPadding = 24.0;
  static const double _headerBottomPadding = 8.0;
  static const double _tileSpacing = 4.0;

  @override
  Widget build(BuildContext context) {
    return buildSectionBody(context);
  }

  Widget buildSectionBody(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.of(context).textScaler;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (Fluent style)
          if (title != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: textScaler.scale(_headerTopPadding),
                bottom: textScaler.scale(_headerBottomPadding),
                start: 4,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: theme.themeData.titleTextColor ?? colorScheme.onSurface,
                  fontSize: _headerFontSize,
                  fontWeight: FontWeight.w600,
                ),
                child: title!,
              ),
            ),

          // Tiles with spacing (no wrapper card)
          buildTileList(context),
        ],
      ),
    );
  }

  Widget buildTileList(BuildContext context) {
    // Use Column with spacing instead of ListView for Fluent Design
    // This allows individual card styling per tile
    return ListView.separated(
      shrinkWrap: true,
      itemCount: tiles.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
      separatorBuilder: (BuildContext context, int index) {
        // Fluent uses spacing between cards, not dividers
        return SizedBox(height: _tileSpacing);
      },
    );
  }
}
