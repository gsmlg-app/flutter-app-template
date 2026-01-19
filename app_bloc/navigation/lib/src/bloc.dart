import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'event.dart';
part 'state.dart';

/// BLoC for managing app navigation state
///
/// This bloc manages the current navigation destination and provides
/// events for navigation actions that can be triggered from anywhere
/// in the app (including gamepad input, keyboard shortcuts, etc.)
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc({
    required this.navigatorKey,
    required List<NavigationDestination> destinations,
  }) : super(NavigationState(destinations: destinations)) {
    on<NavigateToIndex>(_onNavigateToIndex);
    on<NavigateToName>(_onNavigateToName);
    on<NavigateNext>(_onNavigateNext);
    on<NavigatePrevious>(_onNavigatePrevious);
    on<NavigateBack>(_onNavigateBack);
  }

  /// The navigator key for accessing the navigator context
  final GlobalKey<NavigatorState> navigatorKey;

  void _onNavigateToIndex(
    NavigateToIndex event,
    Emitter<NavigationState> emit,
  ) {
    if (event.index >= 0 && event.index < state.destinations.length) {
      emit(state.copyWith(currentIndex: event.index));
      _navigateToDestination(event.index);
    }
  }

  void _onNavigateToName(NavigateToName event, Emitter<NavigationState> emit) {
    final index = state.destinations.indexWhere(
      (d) => d.key == Key(event.name),
    );
    if (index >= 0) {
      emit(state.copyWith(currentIndex: index));
      _navigateToDestination(index);
    }
  }

  void _onNavigateNext(NavigateNext event, Emitter<NavigationState> emit) {
    final nextIndex = state.currentIndex < state.destinations.length - 1
        ? state.currentIndex + 1
        : 0;
    emit(state.copyWith(currentIndex: nextIndex));
    _navigateToDestination(nextIndex);
  }

  void _onNavigatePrevious(
    NavigatePrevious event,
    Emitter<NavigationState> emit,
  ) {
    final prevIndex = state.currentIndex > 0
        ? state.currentIndex - 1
        : state.destinations.length - 1;
    emit(state.copyWith(currentIndex: prevIndex));
    _navigateToDestination(prevIndex);
  }

  void _onNavigateBack(NavigateBack event, Emitter<NavigationState> emit) {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToDestination(int index) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final destination = state.destinations[index];
      final name =
          (destination.key as ValueKey<String>?)?.value ??
          destination.key.toString();
      context.goNamed(name);
    }
  }
}
