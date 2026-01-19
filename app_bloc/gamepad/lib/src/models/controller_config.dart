import 'package:equatable/equatable.dart';

/// Configuration for gamepad button mappings
class ControllerConfig extends Equatable {
  const ControllerConfig({
    this.confirmButton = GamepadButton.a,
    this.backButton = GamepadButton.b,
    this.menuButton = GamepadButton.start,
    this.prevTabButton = GamepadButton.leftShoulder,
    this.nextTabButton = GamepadButton.rightShoulder,
    this.deadzone = 0.2,
    this.enabled = true,
  });

  /// Button for confirm/select action
  final GamepadButton confirmButton;

  /// Button for back/cancel action
  final GamepadButton backButton;

  /// Button for menu action
  final GamepadButton menuButton;

  /// Button for previous tab navigation
  final GamepadButton prevTabButton;

  /// Button for next tab navigation
  final GamepadButton nextTabButton;

  /// Analog stick deadzone (0.0 - 1.0)
  final double deadzone;

  /// Whether gamepad input is enabled
  final bool enabled;

  @override
  List<Object?> get props => [
    confirmButton,
    backButton,
    menuButton,
    prevTabButton,
    nextTabButton,
    deadzone,
    enabled,
  ];

  ControllerConfig copyWith({
    GamepadButton? confirmButton,
    GamepadButton? backButton,
    GamepadButton? menuButton,
    GamepadButton? prevTabButton,
    GamepadButton? nextTabButton,
    double? deadzone,
    bool? enabled,
  }) {
    return ControllerConfig(
      confirmButton: confirmButton ?? this.confirmButton,
      backButton: backButton ?? this.backButton,
      menuButton: menuButton ?? this.menuButton,
      prevTabButton: prevTabButton ?? this.prevTabButton,
      nextTabButton: nextTabButton ?? this.nextTabButton,
      deadzone: deadzone ?? this.deadzone,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'confirmButton': confirmButton.index,
      'backButton': backButton.index,
      'menuButton': menuButton.index,
      'prevTabButton': prevTabButton.index,
      'nextTabButton': nextTabButton.index,
      'deadzone': deadzone,
      'enabled': enabled,
    };
  }

  /// Create from JSON
  factory ControllerConfig.fromJson(Map<String, dynamic> json) {
    return ControllerConfig(
      confirmButton: GamepadButton.values[json['confirmButton'] as int? ?? 0],
      backButton: GamepadButton.values[json['backButton'] as int? ?? 1],
      menuButton: GamepadButton.values[json['menuButton'] as int? ?? 6],
      prevTabButton: GamepadButton.values[json['prevTabButton'] as int? ?? 4],
      nextTabButton: GamepadButton.values[json['nextTabButton'] as int? ?? 5],
      deadzone: (json['deadzone'] as num?)?.toDouble() ?? 0.2,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// Gamepad button identifiers
enum GamepadButton {
  a,
  b,
  x,
  y,
  leftShoulder,
  rightShoulder,
  start,
  select,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  leftStick,
  rightStick,
}

extension GamepadButtonExtension on GamepadButton {
  String get displayName {
    switch (this) {
      case GamepadButton.a:
        return 'A / Cross';
      case GamepadButton.b:
        return 'B / Circle';
      case GamepadButton.x:
        return 'X / Square';
      case GamepadButton.y:
        return 'Y / Triangle';
      case GamepadButton.leftShoulder:
        return 'LB / L1';
      case GamepadButton.rightShoulder:
        return 'RB / R1';
      case GamepadButton.start:
        return 'Start / Options';
      case GamepadButton.select:
        return 'Select / Share';
      case GamepadButton.dpadUp:
        return 'D-Pad Up';
      case GamepadButton.dpadDown:
        return 'D-Pad Down';
      case GamepadButton.dpadLeft:
        return 'D-Pad Left';
      case GamepadButton.dpadRight:
        return 'D-Pad Right';
      case GamepadButton.leftStick:
        return 'Left Stick Click';
      case GamepadButton.rightStick:
        return 'Right Stick Click';
    }
  }
}
