part of 'bloc.dart';

/// State class for navigation
class NavigationState extends Equatable {
  const NavigationState({
    required this.destinations,
    this.currentIndex = 0,
    this.isNavigationExtended,
  });

  /// List of navigation destinations
  final List<NavigationDestination> destinations;

  /// Current navigation index
  final int currentIndex;

  /// User preference for the desktop rail; null uses the responsive default.
  final bool? isNavigationExtended;

  /// Current destination
  NavigationDestination get currentDestination => destinations[currentIndex];

  /// Check if we're at the first destination
  bool get isFirst => currentIndex == 0;

  /// Check if we're at the last destination
  bool get isLast => currentIndex == destinations.length - 1;

  @override
  List<Object?> get props => [destinations, currentIndex, isNavigationExtended];

  NavigationState copyWith({
    List<NavigationDestination>? destinations,
    int? currentIndex,
    bool? isNavigationExtended,
  }) {
    return NavigationState(
      destinations: destinations ?? this.destinations,
      currentIndex: currentIndex ?? this.currentIndex,
      isNavigationExtended: isNavigationExtended ?? this.isNavigationExtended,
    );
  }
}
