part of 'bloc.dart';

/// Base class for gamepad events
sealed class GamepadEvent {
  const GamepadEvent();
}

/// Start listening to gamepad events
final class GamepadStartListening extends GamepadEvent {
  const GamepadStartListening();
}

/// Stop listening to gamepad events
final class GamepadStopListening extends GamepadEvent {
  const GamepadStopListening();
}

/// Refresh the list of connected controllers
final class GamepadRefreshControllers extends GamepadEvent {
  const GamepadRefreshControllers();
}

/// Update the gamepad configuration
final class GamepadUpdateConfig extends GamepadEvent {
  const GamepadUpdateConfig(this.config);

  final ControllerConfig config;
}

/// Toggle gamepad input enabled/disabled
final class GamepadToggleEnabled extends GamepadEvent {
  const GamepadToggleEnabled();
}

/// Internal event when a gamepad action is received
final class GamepadActionReceived extends GamepadEvent {
  const GamepadActionReceived(this.action);

  final GamepadAction action;
}
