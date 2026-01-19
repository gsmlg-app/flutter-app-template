import 'package:flutter/material.dart';
import 'package:nav_bloc/nav_bloc.dart';

import 'gamepad_service.dart';

/// Controller for managing gamepad-based navigation
///
/// This controller listens to gamepad events and dispatches appropriate
/// events to the NavigationBloc for navigation, and handles focus
/// management for in-screen navigation.
class GamepadController extends ChangeNotifier {
  GamepadController({required this.navigationBloc}) {
    _gamepadService.addListener(_handleGamepadAction);
    _gamepadService.startListening();
  }

  /// The NavigationBloc to dispatch navigation events to
  final NavigationBloc navigationBloc;

  final GamepadService _gamepadService = GamepadService.instance;

  void _handleGamepadAction(GamepadAction action) {
    switch (action) {
      case GamepadAction.shoulderLeft:
        navigationBloc.add(const NavigatePrevious());
        break;
      case GamepadAction.shoulderRight:
        navigationBloc.add(const NavigateNext());
        break;
      case GamepadAction.left:
        _moveFocus(TraversalDirection.left);
        break;
      case GamepadAction.right:
        _moveFocus(TraversalDirection.right);
        break;
      case GamepadAction.up:
        _moveFocus(TraversalDirection.up);
        break;
      case GamepadAction.down:
        _moveFocus(TraversalDirection.down);
        break;
      case GamepadAction.confirm:
        _activateFocus();
        break;
      case GamepadAction.back:
        navigationBloc.add(const NavigateBack());
        break;
      case GamepadAction.menu:
        // Navigate to last destination (typically Settings)
        final lastIndex = navigationBloc.state.destinations.length - 1;
        navigationBloc.add(NavigateToIndex(lastIndex));
        break;
    }
  }

  void _moveFocus(TraversalDirection direction) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) {
      _focusFirst();
      return;
    }
    primaryFocus.focusInDirection(direction);
  }

  void _focusFirst() {
    final context = navigationBloc.navigatorKey.currentContext;
    if (context != null) {
      FocusScope.of(context).nextFocus();
    }
  }

  void _activateFocus() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return;

    final context = primaryFocus.context;
    if (context == null) return;

    // Try to find and activate interactive widgets
    context.visitAncestorElements((element) {
      final w = element.widget;
      if (w is InkWell && w.onTap != null) {
        w.onTap!();
        return false;
      }
      if (w is GestureDetector && w.onTap != null) {
        w.onTap!();
        return false;
      }
      if (w is TextButton && w.onPressed != null) {
        w.onPressed!();
        return false;
      }
      if (w is ElevatedButton && w.onPressed != null) {
        w.onPressed!();
        return false;
      }
      if (w is IconButton && w.onPressed != null) {
        w.onPressed!();
        return false;
      }
      if (w is ListTile && w.onTap != null) {
        w.onTap!();
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    _gamepadService.removeListener(_handleGamepadAction);
    super.dispose();
  }
}
