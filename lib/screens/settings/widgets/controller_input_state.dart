import 'package:flutter/foundation.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';

/// Immutable snapshot of all controller inputs for the test view.
class ControllerInputState {
  const ControllerInputState({
    this.leftStickX = 0,
    this.leftStickY = 0,
    this.rightStickX = 0,
    this.rightStickY = 0,
    this.leftTrigger = 0,
    this.rightTrigger = 0,
    this.pressedButtons = const {},
  });

  final double leftStickX;
  final double leftStickY;
  final double rightStickX;
  final double rightStickY;

  /// 0.0 – 1.0
  final double leftTrigger;

  /// 0.0 – 1.0
  final double rightTrigger;

  final Set<String> pressedButtons;

  bool isPressed(String button) => pressedButtons.contains(button);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ControllerInputState &&
          leftStickX == other.leftStickX &&
          leftStickY == other.leftStickY &&
          rightStickX == other.rightStickX &&
          rightStickY == other.rightStickY &&
          leftTrigger == other.leftTrigger &&
          rightTrigger == other.rightTrigger &&
          setEquals(pressedButtons, other.pressedButtons);

  @override
  int get hashCode => Object.hash(
        leftStickX,
        leftStickY,
        rightStickX,
        rightStickY,
        leftTrigger,
        rightTrigger,
        Object.hashAll(pressedButtons.toList()..sort()),
      );

  ControllerInputState copyWith({
    double? leftStickX,
    double? leftStickY,
    double? rightStickX,
    double? rightStickY,
    double? leftTrigger,
    double? rightTrigger,
    Set<String>? pressedButtons,
  }) {
    return ControllerInputState(
      leftStickX: leftStickX ?? this.leftStickX,
      leftStickY: leftStickY ?? this.leftStickY,
      rightStickX: rightStickX ?? this.rightStickX,
      rightStickY: rightStickY ?? this.rightStickY,
      leftTrigger: leftTrigger ?? this.leftTrigger,
      rightTrigger: rightTrigger ?? this.rightTrigger,
      pressedButtons: pressedButtons ?? this.pressedButtons,
    );
  }
}

/// Well-known button identifiers used as keys in
/// [ControllerInputState.pressedButtons].
abstract final class ButtonId {
  static const a = 'a';
  static const b = 'b';
  static const x = 'x';
  static const y = 'y';
  static const lb = 'lb';
  static const rb = 'rb';
  static const lt = 'lt';
  static const rt = 'rt';
  static const ls = 'ls';
  static const rs = 'rs';
  static const dpadUp = 'dpad_up';
  static const dpadDown = 'dpad_down';
  static const dpadLeft = 'dpad_left';
  static const dpadRight = 'dpad_right';
  static const start = 'start';
  static const back = 'back';
  static const guide = 'guide';
}

/// Whether the raw value represents "pressed" for the given key.
///
/// On Android, button events use `KeyEvent.action.toDouble()` where
/// ACTION_DOWN=0 and ACTION_UP=1, so pressed = value < 0.5.
/// On other platforms, pressed = value > 0.5.
bool _isPressed(String rawKey, double value) {
  if (rawKey.startsWith('KEYCODE_')) {
    return value < 0.5;
  }
  return value > 0.5;
}

/// Maps a raw gamepad key name to a [ButtonId] (or null for axes / unknown).
String? identifyButton(String rawKey) {
  final k = rawKey.toLowerCase();

  // ── Android KEYCODE_ names (from KeyEvent.keyCodeToString) ──
  if (k == 'keycode_button_a') {
    return ButtonId.a;
  }
  if (k == 'keycode_button_b') {
    return ButtonId.b;
  }
  if (k == 'keycode_button_x') {
    return ButtonId.x;
  }
  if (k == 'keycode_button_y') {
    return ButtonId.y;
  }
  if (k == 'keycode_button_l1') {
    return ButtonId.lb;
  }
  if (k == 'keycode_button_r1') {
    return ButtonId.rb;
  }
  if (k == 'keycode_button_l2') {
    return ButtonId.lt;
  }
  if (k == 'keycode_button_r2') {
    return ButtonId.rt;
  }
  if (k == 'keycode_button_thumbl') {
    return ButtonId.ls;
  }
  if (k == 'keycode_button_thumbr') {
    return ButtonId.rs;
  }
  if (k == 'keycode_button_start') {
    return ButtonId.start;
  }
  if (k == 'keycode_button_select') {
    return ButtonId.back;
  }
  if (k == 'keycode_button_mode') {
    return ButtonId.guide;
  }
  if (k == 'keycode_dpad_up') {
    return ButtonId.dpadUp;
  }
  if (k == 'keycode_dpad_down') {
    return ButtonId.dpadDown;
  }
  if (k == 'keycode_dpad_left') {
    return ButtonId.dpadLeft;
  }
  if (k == 'keycode_dpad_right') {
    return ButtonId.dpadRight;
  }

  // ── Generic / Web / Desktop names ──

  // Face buttons
  if (k == 'a' || k == 'button a' || k == 'button 0' || k == 'button0' ||
      k == 'buttona' || k == 'cross') {
    return ButtonId.a;
  }
  if (k == 'b' || k == 'button b' || k == 'button 1' || k == 'button1' ||
      k == 'buttonb' || k == 'circle') {
    return ButtonId.b;
  }
  if (k == 'x' || k == 'button x' || k == 'button 2' || k == 'button2' ||
      k == 'buttonx' || k == 'square') {
    return ButtonId.x;
  }
  if (k == 'y' || k == 'button y' || k == 'button 3' || k == 'button3' ||
      k == 'buttony' || k == 'triangle') {
    return ButtonId.y;
  }

  // Shoulders
  if (k == 'l1' || k == 'lb' || k == 'leftshoulder' || k == 'button 4' ||
      k == 'button4') {
    return ButtonId.lb;
  }
  if (k == 'r1' || k == 'rb' || k == 'rightshoulder' || k == 'button 5' ||
      k == 'button5') {
    return ButtonId.rb;
  }

  // Triggers (digital press – analog handled separately)
  if (k == 'l2' || k == 'lt' || k == 'lefttrigger' || k == 'button 6' ||
      k == 'button6') {
    return ButtonId.lt;
  }
  if (k == 'r2' || k == 'rt' || k == 'righttrigger' || k == 'button 7' ||
      k == 'button7') {
    return ButtonId.rt;
  }

  // Stick press
  if (k == 'l3' || k == 'leftstick' || k == 'leftstickbutton' ||
      k == 'button 10' || k == 'button10') {
    return ButtonId.ls;
  }
  if (k == 'r3' || k == 'rightstick' || k == 'rightstickbutton' ||
      k == 'button 11' || k == 'button11') {
    return ButtonId.rs;
  }

  // D-pad
  if (k == 'button 12' || k == 'button12') {
    return ButtonId.dpadUp;
  }
  if (k == 'button 13' || k == 'button13') {
    return ButtonId.dpadDown;
  }
  if (k == 'button 14' || k == 'button14') {
    return ButtonId.dpadLeft;
  }
  if (k == 'button 15' || k == 'button15') {
    return ButtonId.dpadRight;
  }
  if ((k.contains('dpad') || k.contains('pov')) && k.contains('up')) {
    return ButtonId.dpadUp;
  }
  if ((k.contains('dpad') || k.contains('pov')) && k.contains('down')) {
    return ButtonId.dpadDown;
  }
  if ((k.contains('dpad') || k.contains('pov')) && k.contains('left')) {
    return ButtonId.dpadLeft;
  }
  if ((k.contains('dpad') || k.contains('pov')) && k.contains('right')) {
    return ButtonId.dpadRight;
  }

  // Center buttons (Standard Gamepad: button 8 = back, button 9 = start)
  if (k == 'start' || k == 'options' || k == 'button 9' || k == 'button9') {
    return ButtonId.start;
  }
  if (k == 'select' || k == 'back' || k == 'share' || k == 'button 8' ||
      k == 'button8') {
    return ButtonId.back;
  }
  if (k == 'guide' || k == 'home' || k == 'xbox' || k == 'ps' ||
      k == 'button 16' || k == 'button16') {
    return ButtonId.guide;
  }

  return null;
}

/// Whether a raw key represents an axis (stick / trigger analog).
bool _isLeftStickX(String k) =>
    k == 'axis_x' ||
    k == 'leftx' ||
    k == 'left x' ||
    k == 'leftstickx' ||
    k == 'axis 0' ||
    k == 'axis0' ||
    k == 'analog 0' ||
    k == 'analog0';

bool _isLeftStickY(String k) =>
    k == 'axis_y' ||
    k == 'lefty' ||
    k == 'left y' ||
    k == 'leftsticky' ||
    k == 'axis 1' ||
    k == 'axis1' ||
    k == 'analog 1' ||
    k == 'analog1';

// Linux joystick axis layout varies by controller:
//   Layout A: 0=LX, 1=LY, 2=RX, 3=RY, 4=LT, 5=RT  (e.g. some Xbox clones)
//   Layout B: 0=LX, 1=LY, 2=RX, 3=RX', 4=RY', 5=RY, 6=DX, 7=DY  (e.g. PS4/DualSense)
// We match both layouts; the duplicates are harmless (same physical axis).

bool _isRightStickX(String k) =>
    k == 'axis_z' ||
    k == 'axis_rx' ||
    k == 'rightx' ||
    k == 'right x' ||
    k == 'rightstickx' ||
    k == 'axis 2' ||
    k == 'axis2' ||
    k == 'analog 2' ||
    k == 'analog2' ||
    k == 'analog 3' || // ABS_RX on Layout B controllers
    k == 'analog3';

bool _isRightStickY(String k) =>
    k == 'axis_rz' ||
    k == 'axis_ry' ||
    k == 'righty' ||
    k == 'right y' ||
    k == 'rightsticky' ||
    k == 'axis 3' ||
    k == 'axis3' ||
    k == 'analog 4' || // ABS_RY on Layout B controllers
    k == 'analog4' ||
    k == 'analog 5' || // ABS_RZ on Layout B controllers
    k == 'analog5';

bool _isLeftTriggerAxis(String k) =>
    k == 'axis_ltrigger' ||
    k == 'axis_brake' ||
    k == 'lefttrigger' ||
    k == 'axis 4' ||
    k == 'axis4';

bool _isRightTriggerAxis(String k) =>
    k == 'axis_rtrigger' ||
    k == 'axis_gas' ||
    k == 'righttrigger' ||
    k == 'axis 5' ||
    k == 'axis5';

bool _isDpadHatX(String k) =>
    k == 'axis_hat_x' ||
    k == 'analog 6' || // Linux joystick HAT0X
    k == 'analog6';
bool _isDpadHatY(String k) =>
    k == 'axis_hat_y' ||
    k == 'analog 7' || // Linux joystick HAT0Y
    k == 'analog7';

/// Accumulates a raw event into an existing [ControllerInputState].
ControllerInputState accumulateRawEvent(
  ControllerInputState state,
  String rawKey,
  double value,
) {
  final k = rawKey.toLowerCase();

  // ── Analog axes ──
  if (_isLeftStickX(k)) {
    return state.copyWith(leftStickX: value);
  }
  if (_isLeftStickY(k)) {
    return state.copyWith(leftStickY: -value);
  }
  if (_isRightStickX(k)) {
    return state.copyWith(rightStickX: value);
  }
  if (_isRightStickY(k)) {
    return state.copyWith(rightStickY: -value);
  }
  if (_isLeftTriggerAxis(k)) {
    return state.copyWith(leftTrigger: value.clamp(0, 1));
  }
  if (_isRightTriggerAxis(k)) {
    return state.copyWith(rightTrigger: value.clamp(0, 1));
  }

  // ── D-pad analog axes (Android HAT_X / HAT_Y) ──
  // HAT_X: -1 = left, 1 = right, 0 = neutral
  // HAT_Y: inverted by gamepads package, so 1 = up, -1 = down, 0 = neutral
  if (_isDpadHatX(k)) {
    final pressed = Set<String>.of(state.pressedButtons);
    if (value < -0.5) {
      pressed.add(ButtonId.dpadLeft);
      pressed.remove(ButtonId.dpadRight);
    } else if (value > 0.5) {
      pressed.remove(ButtonId.dpadLeft);
      pressed.add(ButtonId.dpadRight);
    } else {
      pressed.remove(ButtonId.dpadLeft);
      pressed.remove(ButtonId.dpadRight);
    }
    return state.copyWith(pressedButtons: pressed);
  }
  if (_isDpadHatY(k)) {
    final pressed = Set<String>.of(state.pressedButtons);
    if (value > 0.5) {
      pressed.add(ButtonId.dpadUp);
      pressed.remove(ButtonId.dpadDown);
    } else if (value < -0.5) {
      pressed.remove(ButtonId.dpadUp);
      pressed.add(ButtonId.dpadDown);
    } else {
      pressed.remove(ButtonId.dpadUp);
      pressed.remove(ButtonId.dpadDown);
    }
    return state.copyWith(pressedButtons: pressed);
  }

  // ── Digital buttons ──
  final id = identifyButton(rawKey);
  if (id != null) {
    final isDown = _isPressed(rawKey, value);
    final pressed = Set<String>.of(state.pressedButtons);
    if (isDown) {
      pressed.add(id);
    } else {
      pressed.remove(id);
    }
    // When triggers arrive as digital buttons (Linux), also drive the
    // analog trigger bar so the visualizer shows feedback.
    if (id == ButtonId.lt) {
      return state.copyWith(
        pressedButtons: pressed,
        leftTrigger: isDown ? 1.0 : 0.0,
      );
    }
    if (id == ButtonId.rt) {
      return state.copyWith(
        pressedButtons: pressed,
        rightTrigger: isDown ? 1.0 : 0.0,
      );
    }
    return state.copyWith(pressedButtons: pressed);
  }

  return state;
}

/// Returns the label for a button based on controller type.
String buttonLabel(
  String buttonId,
  ControllerType controllerType,
) {
  final ps = controllerType == ControllerType.playstation;
  switch (buttonId) {
    case ButtonId.a:
      return ps ? 'Cross' : 'A';
    case ButtonId.b:
      return ps ? 'Circle' : 'B';
    case ButtonId.x:
      return ps ? 'Square' : 'X';
    case ButtonId.y:
      return ps ? 'Triangle' : 'Y';
    case ButtonId.lb:
      return ps ? 'L1' : 'LB';
    case ButtonId.rb:
      return ps ? 'R1' : 'RB';
    case ButtonId.lt:
      return ps ? 'L2' : 'LT';
    case ButtonId.rt:
      return ps ? 'R2' : 'RT';
    case ButtonId.ls:
      return ps ? 'L3' : 'LS';
    case ButtonId.rs:
      return ps ? 'R3' : 'RS';
    case ButtonId.start:
      return ps ? 'Options' : 'Start';
    case ButtonId.back:
      return ps ? 'Share' : 'Back';
    case ButtonId.guide:
      return ps ? 'PS' : 'Guide';
    default:
      return buttonId.toUpperCase();
  }
}
