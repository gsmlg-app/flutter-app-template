import 'package:app_gamepad/app_gamepad.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/controller_config.dart';
import 'models/controller_info.dart';

part 'event.dart';
part 'state.dart';

/// BLoC for managing gamepad state, configuration, and input handling
class GamepadBloc extends Bloc<GamepadEvent, GamepadState> {
  GamepadBloc({
    required this.navigatorKey,
    required this.routeNames,
    ControllerConfig? initialConfig,
  }) : super(GamepadState(config: initialConfig ?? const ControllerConfig())) {
    on<GamepadStartListening>(_onStartListening);
    on<GamepadStopListening>(_onStopListening);
    on<GamepadRefreshControllers>(_onRefreshControllers);
    on<GamepadUpdateConfig>(_onUpdateConfig);
    on<GamepadToggleEnabled>(_onToggleEnabled);
    on<GamepadActionReceived>(_onActionReceived);
  }

  /// The navigator key for accessing navigation context
  final GlobalKey<NavigatorState> navigatorKey;

  /// List of route names for tab navigation
  final List<String> routeNames;

  /// Current navigation index
  int _currentIndex = 0;

  final GamepadService _gamepadService = GamepadService.instance;

  void _onStartListening(
    GamepadStartListening event,
    Emitter<GamepadState> emit,
  ) {
    if (state.isListening) return;

    _gamepadService.addListener(_handleGamepadAction);
    _gamepadService.startListening();
    emit(state.copyWith(isListening: true));

    // Also refresh connected controllers
    add(const GamepadRefreshControllers());
  }

  void _onStopListening(
    GamepadStopListening event,
    Emitter<GamepadState> emit,
  ) {
    if (!state.isListening) return;

    _gamepadService.removeListener(_handleGamepadAction);
    _gamepadService.stopListening();
    emit(state.copyWith(isListening: false));
  }

  Future<void> _onRefreshControllers(
    GamepadRefreshControllers event,
    Emitter<GamepadState> emit,
  ) async {
    final gamepads = await _gamepadService.getConnectedGamepads();
    final controllers = gamepads.map((gp) {
      return ControllerInfo(
        id: gp.id,
        name: gp.name,
        type: _detectControllerType(gp.name),
      );
    }).toList();

    emit(state.copyWith(connectedControllers: controllers));
  }

  void _onUpdateConfig(GamepadUpdateConfig event, Emitter<GamepadState> emit) {
    emit(state.copyWith(config: event.config));
  }

  void _onToggleEnabled(
    GamepadToggleEnabled event,
    Emitter<GamepadState> emit,
  ) {
    final newConfig = state.config.copyWith(enabled: !state.config.enabled);
    emit(state.copyWith(config: newConfig));
  }

  void _onActionReceived(
    GamepadActionReceived event,
    Emitter<GamepadState> emit,
  ) {
    // Update last action for UI feedback
    emit(state.copyWith(lastAction: event.action));
  }

  void _handleGamepadAction(GamepadAction action) {
    // Notify state of action (for UI feedback)
    add(GamepadActionReceived(action));

    // Don't process if disabled
    if (!state.config.enabled) return;

    switch (action) {
      case GamepadAction.shoulderLeft:
        _navigatePrevious();
        break;
      case GamepadAction.shoulderRight:
        _navigateNext();
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
        _navigateBack();
        break;
      case GamepadAction.menu:
        _navigateToIndex(routeNames.length - 1);
        break;
    }
  }

  void _navigateToIndex(int index) {
    if (index < 0 || index >= routeNames.length) return;
    final context = navigatorKey.currentContext;
    if (context != null) {
      _currentIndex = index;
      context.goNamed(routeNames[index]);
    }
  }

  void _navigateNext() {
    final nextIndex =
        _currentIndex < routeNames.length - 1 ? _currentIndex + 1 : 0;
    _navigateToIndex(nextIndex);
  }

  void _navigatePrevious() {
    final prevIndex =
        _currentIndex > 0 ? _currentIndex - 1 : routeNames.length - 1;
    _navigateToIndex(prevIndex);
  }

  void _navigateBack() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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
    final context = navigatorKey.currentContext;
    if (context != null) {
      FocusScope.of(context).nextFocus();
    }
  }

  void _activateFocus() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return;

    final context = primaryFocus.context;
    if (context == null) return;

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

  ControllerType _detectControllerType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('xbox') || lowerName.contains('microsoft')) {
      return ControllerType.xbox;
    }
    if (lowerName.contains('playstation') ||
        lowerName.contains('dualshock') ||
        lowerName.contains('dualsense') ||
        lowerName.contains('sony')) {
      return ControllerType.playstation;
    }
    if (lowerName.contains('nintendo') ||
        lowerName.contains('switch') ||
        lowerName.contains('joy-con') ||
        lowerName.contains('pro controller')) {
      return ControllerType.nintendo;
    }
    if (lowerName.contains('controller') || lowerName.contains('gamepad')) {
      return ControllerType.generic;
    }
    return ControllerType.unknown;
  }

  @override
  Future<void> close() {
    if (state.isListening) {
      _gamepadService.removeListener(_handleGamepadAction);
    }
    return super.close();
  }
}
