import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

export 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class AppAdaptiveScaffold extends StatelessWidget {
  static const appSmallBreakpoint = Breakpoint(
    beginWidth: -1,
    endWidth: 720,
  );
  static const appMediumBreakpoint = Breakpoint(
    beginWidth: 720,
    endWidth: 1194,
  );
  static const appLargeBreakpoint = Breakpoint(
    beginWidth: 1194,
  );

  final List<NavigationDestination> destinations;
  final int? selectedIndex;
  final Widget? leadingUnextendedNavRail;
  final Widget? leadingExtendedNavRail;
  final Widget? trailingNavRail;
  final Widget Function(BuildContext)? smallBody;
  final Widget Function(BuildContext)? body;
  final Widget Function(BuildContext)? largeBody;
  final Widget Function(BuildContext)? smallSecondaryBody;
  final Widget Function(BuildContext)? secondaryBody;
  final Widget Function(BuildContext)? largeSecondaryBody;
  final double? bodyRatio;
  final Breakpoint smallBreakpoint;
  final Breakpoint mediumBreakpoint;
  final Breakpoint largeBreakpoint;
  final Breakpoint drawerBreakpoint;
  final bool internalAnimations;
  final Axis bodyOrientation;
  final dynamic Function(int)? onSelectedIndexChange;
  final bool useDrawer;
  final PreferredSizeWidget? appBar;
  final double navigationRailWidth;
  final double extendedNavigationRailWidth;
  final Breakpoint? appBarBreakpoint;

  const AppAdaptiveScaffold({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.leadingUnextendedNavRail,
    this.leadingExtendedNavRail,
    this.trailingNavRail,
    this.smallBody,
    this.body,
    this.largeBody,
    this.smallSecondaryBody,
    this.secondaryBody,
    this.largeSecondaryBody,
    this.bodyRatio,
    this.smallBreakpoint = appSmallBreakpoint,
    this.mediumBreakpoint = appMediumBreakpoint,
    this.largeBreakpoint = appLargeBreakpoint,
    this.drawerBreakpoint = Breakpoints.smallDesktop,
    this.internalAnimations = false,
    this.bodyOrientation = Axis.horizontal,
    this.onSelectedIndexChange,
    this.useDrawer = false,
    this.appBar,
    this.navigationRailWidth = 72,
    this.extendedNavigationRailWidth = 192,
    this.appBarBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: destinations,
      selectedIndex: selectedIndex,
      leadingUnextendedNavRail: leadingUnextendedNavRail,
      leadingExtendedNavRail: leadingExtendedNavRail,
      trailingNavRail: trailingNavRail,
      smallBody: smallBody,
      body: body,
      largeBody: largeBody,
      smallSecondaryBody: smallSecondaryBody,
      secondaryBody: secondaryBody,
      largeSecondaryBody: largeSecondaryBody,
      bodyRatio: bodyRatio,
      smallBreakpoint: smallBreakpoint,
      mediumBreakpoint: mediumBreakpoint,
      largeBreakpoint: largeBreakpoint,
      drawerBreakpoint: drawerBreakpoint,
      internalAnimations: internalAnimations,
      bodyOrientation: bodyOrientation,
      onSelectedIndexChange: onSelectedIndexChange,
      useDrawer: useDrawer,
      appBar: appBar,
      navigationRailWidth: navigationRailWidth,
      extendedNavigationRailWidth: extendedNavigationRailWidth,
      appBarBreakpoint: appBarBreakpoint,
    );
  }
}
