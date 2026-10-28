part of 'bloc.dart';

/// Base class for navigation events
sealed class NavigationEvent {
  const NavigationEvent();
}

/// Navigate to a specific index
final class NavigateToIndex extends NavigationEvent {
  final int index;

  const NavigateToIndex(this.index);
}

/// Navigate to a destination by name
final class NavigateToName extends NavigationEvent {
  final String name;

  const NavigateToName(this.name);
}

/// Navigate to the next destination (wraps around)
final class NavigateNext extends NavigationEvent {
  const NavigateNext();
}

/// Navigate to the previous destination (wraps around)
final class NavigatePrevious extends NavigationEvent {
  const NavigatePrevious();
}

/// Go back in navigation history
final class NavigateBack extends NavigationEvent {
  const NavigateBack();
}

/// Sets the shared desktop navigation rail expansion preference.
final class SetNavigationExtended extends NavigationEvent {
  const SetNavigationExtended(this.extended);

  final bool extended;
}
