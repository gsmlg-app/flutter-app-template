part of 'bloc.dart';

/// State class for gamepad
class GamepadState extends Equatable {
  const GamepadState({
    required this.config,
    this.connectedControllers = const [],
    this.isListening = false,
    this.lastAction,
  });

  /// Current gamepad configuration
  final ControllerConfig config;

  /// List of connected controllers
  final List<ControllerInfo> connectedControllers;

  /// Whether currently listening to gamepad events
  final bool isListening;

  /// Last received gamepad action (for UI feedback)
  final GamepadAction? lastAction;

  /// Whether gamepad input is enabled
  bool get isEnabled => config.enabled;

  /// Whether any controller is connected
  bool get hasController => connectedControllers.isNotEmpty;

  @override
  List<Object?> get props => [
    config,
    connectedControllers,
    isListening,
    lastAction,
  ];

  GamepadState copyWith({
    ControllerConfig? config,
    List<ControllerInfo>? connectedControllers,
    bool? isListening,
    GamepadAction? lastAction,
  }) {
    return GamepadState(
      config: config ?? this.config,
      connectedControllers: connectedControllers ?? this.connectedControllers,
      isListening: isListening ?? this.isListening,
      lastAction: lastAction ?? this.lastAction,
    );
  }
}
