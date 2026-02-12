part of 'bloc.dart';

/// State class for gamepad
class GamepadState extends Equatable {
  const GamepadState({
    required this.config,
    this.connectedControllers = const [],
    this.isListening = false,
    this.lastAction,
    this.isTestingMode = false,
    this.actionCounter = 0,
  });

  /// Current gamepad configuration
  final ControllerConfig config;

  /// List of connected controllers
  final List<ControllerInfo> connectedControllers;

  /// Whether currently listening to gamepad events
  final bool isListening;

  /// Last received gamepad action (for UI feedback)
  final GamepadAction? lastAction;

  /// Whether key binding test mode is active (suppresses navigation/focus)
  final bool isTestingMode;

  /// Incremented on every action to ensure unique states for BlocBuilder
  final int actionCounter;

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
    isTestingMode,
    actionCounter,
  ];

  GamepadState copyWith({
    ControllerConfig? config,
    List<ControllerInfo>? connectedControllers,
    bool? isListening,
    GamepadAction? lastAction,
    bool? isTestingMode,
    int? actionCounter,
  }) {
    return GamepadState(
      config: config ?? this.config,
      connectedControllers: connectedControllers ?? this.connectedControllers,
      isListening: isListening ?? this.isListening,
      lastAction: lastAction ?? this.lastAction,
      isTestingMode: isTestingMode ?? this.isTestingMode,
      actionCounter: actionCounter ?? this.actionCounter,
    );
  }
}
