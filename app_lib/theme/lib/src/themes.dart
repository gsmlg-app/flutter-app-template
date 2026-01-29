import 'package:app_theme/src/color_schemes/fire.dart' as fire;
import 'package:app_theme/src/color_schemes/green.dart' as green;
import 'package:app_theme/src/color_schemes/violet.dart' as violet;
import 'package:app_theme/src/color_schemes/wheat.dart' as wheat;
import 'package:flutter/material.dart';

// import 'package:app_theme/src/typography.dart';

final themeList = [VioletTheme(), GreenTheme(), FireTheme(), WheatTheme()];

/// Creates a ThemeData with proper visual hierarchy for macOS/desktop.
/// - AppBar: uses surface with subtle tint
/// - NavigationRail: uses secondaryContainer for branded, colorful navigation
ThemeData _buildThemeData(ColorScheme colorScheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // AppBar styling - clean with subtle tint
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    // NavigationRail styling - uses secondary color for branded look
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.secondaryContainer,
      indicatorColor: colorScheme.primary,
      selectedIconTheme: IconThemeData(color: colorScheme.onPrimary),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
      selectedLabelTextStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSecondaryContainer),
    ),
    // NavigationDrawer styling - same as rail for consistency
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colorScheme.secondaryContainer,
      indicatorColor: colorScheme.primary,
    ),
  );
}

abstract class AppTheme {
  const AppTheme({
    required this.name,
    required this.lightTheme,
    required this.darkTheme,
  });
  final String name;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  @override
  String toString() {
    return name;
  }
}

@immutable
class VioletTheme extends AppTheme {
  factory VioletTheme() {
    return VioletTheme._();
  }

  VioletTheme._()
    : super(
        name: 'Violet',
        lightTheme: _buildThemeData(violet.lightColorScheme),
        darkTheme: _buildThemeData(violet.darkColorScheme),
      );
}

@immutable
class GreenTheme extends AppTheme {
  factory GreenTheme() {
    return GreenTheme._();
  }

  GreenTheme._()
    : super(
        name: 'Green',
        lightTheme: _buildThemeData(green.lightColorScheme),
        darkTheme: _buildThemeData(green.darkColorScheme),
      );
}

@immutable
class FireTheme extends AppTheme {
  factory FireTheme() {
    return FireTheme._();
  }

  FireTheme._()
    : super(
        name: 'Fire',
        lightTheme: _buildThemeData(fire.lightColorScheme),
        darkTheme: _buildThemeData(fire.darkColorScheme),
      );
}

@immutable
class WheatTheme extends AppTheme {
  factory WheatTheme() {
    return WheatTheme._();
  }

  WheatTheme._()
    : super(
        name: 'Wheat',
        lightTheme: _buildThemeData(wheat.lightColorScheme),
        darkTheme: _buildThemeData(wheat.darkColorScheme),
      );
}

@immutable
class DynamicTheme extends AppTheme {
  factory DynamicTheme.fromSeed(Color seedColor) {
    return DynamicTheme._(seedColor);
  }

  DynamicTheme._(Color seedColor)
    : super(
        name: 'Dynamic',
        lightTheme: _buildThemeData(
          ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: _buildThemeData(
          ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
        ),
      );
}
