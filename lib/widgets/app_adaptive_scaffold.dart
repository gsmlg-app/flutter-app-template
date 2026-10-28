import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:nav_bloc/nav_bloc.dart';

/// App navigation with Duskmoon's collapsible rail and a shared preference.
class AppAdaptiveScaffold extends StatelessWidget {
  const AppAdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.body,
    this.appBar,
    this.internalAnimations = false,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChange;
  final WidgetBuilder body;
  final PreferredSizeWidget? appBar;
  final bool internalAnimations;

  @override
  Widget build(BuildContext context) {
    final navigation = context.read<NavigationBloc?>();
    // Standalone screen previews retain Duskmoon's local expansion state.
    if (navigation == null) return _scaffold();
    return BlocSelector<NavigationBloc, NavigationState, bool?>(
      bloc: navigation,
      selector: (state) => state.isNavigationExtended,
      builder: (context, extended) => _scaffold(
        extended: extended,
        onExtendedChange: (value) =>
            navigation.add(SetNavigationExtended(value)),
      ),
    );
  }

  Widget _scaffold({bool? extended, ValueChanged<bool>? onExtendedChange}) {
    return DmAdaptiveScaffold(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelectedIndexChange: onSelectedIndexChange,
      body: body,
      appBar: appBar,
      internalAnimations: internalAnimations,
      showCollapseToggle: true,
      isExtendedOverride: extended,
      onExtendedChange: onExtendedChange,
    );
  }
}
