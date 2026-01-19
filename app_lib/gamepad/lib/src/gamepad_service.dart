import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

/// Represents a gamepad navigation action
enum GamepadAction {
  /// Navigate to previous tab/item
  left,

  /// Navigate to next tab/item
  right,

  /// Navigate up in a list
  up,

  /// Navigate down in a list
  down,

  /// Confirm/Select action (A button)
  confirm,

  /// Back/Cancel action (B button)
  back,

  /// Menu/Start button
  menu,

  /// Shoulder button left (L1/LB)
  shoulderLeft,

  /// Shoulder button right (R1/RB)
  shoulderRight,
}

/// Callback type for gamepad actions
typedef GamepadActionCallback = void Function(GamepadAction action);

/// Service for handling gamepad input and converting to navigation actions
class GamepadService {
  GamepadService._();

  static final GamepadService _instance = GamepadService._();

  /// Singleton instance
  static GamepadService get instance => _instance;

  StreamSubscription<GamepadEvent>? _subscription;
  final List<GamepadActionCallback> _listeners = [];

  /// Threshold for analog stick/trigger activation
  static const double _axisThreshold = 0.5;

  /// Debounce duration to prevent rapid-fire events
  static const Duration _debounceDuration = Duration(milliseconds: 150);

  DateTime? _lastEventTime;
  String? _lastKey;

  /// Whether the service is currently listening
  bool get isListening => _subscription != null;

  /// Start listening to gamepad events
  void startListening() {
    if (_subscription != null) return;

    _subscription = Gamepads.events.listen(_handleEvent);
    debugPrint('GamepadService: Started listening for gamepad events');
  }

  /// Stop listening to gamepad events
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('GamepadService: Stopped listening for gamepad events');
  }

  /// Add a listener for gamepad actions
  void addListener(GamepadActionCallback callback) {
    _listeners.add(callback);
  }

  /// Remove a listener
  void removeListener(GamepadActionCallback callback) {
    _listeners.remove(callback);
  }

  /// Get list of connected gamepads
  Future<List<GamepadController>> getConnectedGamepads() async {
    return Gamepads.list();
  }

  void _handleEvent(GamepadEvent event) {
    // Debounce to prevent rapid-fire
    final now = DateTime.now();
    if (_lastEventTime != null &&
        _lastKey == event.key &&
        now.difference(_lastEventTime!) < _debounceDuration) {
      return;
    }

    final action = _mapEventToAction(event);
    if (action != null) {
      _lastEventTime = now;
      _lastKey = event.key;
      _notifyListeners(action);
    }
  }

  GamepadAction? _mapEventToAction(GamepadEvent event) {
    final key = event.key.toLowerCase();
    final value = event.value;

    // Handle button presses (value > 0.5 means pressed)
    if (value > _axisThreshold) {
      // D-pad buttons
      if (_isDpadLeft(key)) return GamepadAction.left;
      if (_isDpadRight(key)) return GamepadAction.right;
      if (_isDpadUp(key)) return GamepadAction.up;
      if (_isDpadDown(key)) return GamepadAction.down;

      // Action buttons
      if (_isConfirmButton(key)) return GamepadAction.confirm;
      if (_isBackButton(key)) return GamepadAction.back;
      if (_isMenuButton(key)) return GamepadAction.menu;

      // Shoulder buttons
      if (_isLeftShoulder(key)) return GamepadAction.shoulderLeft;
      if (_isRightShoulder(key)) return GamepadAction.shoulderRight;
    }

    // Handle analog stick axes
    if (_isLeftStickX(key) || _isRightStickX(key)) {
      if (value < -_axisThreshold) return GamepadAction.left;
      if (value > _axisThreshold) return GamepadAction.right;
    }
    if (_isLeftStickY(key) || _isRightStickY(key)) {
      if (value < -_axisThreshold) return GamepadAction.up;
      if (value > _axisThreshold) return GamepadAction.down;
    }

    return null;
  }

  // D-pad detection - covers various platform key naming conventions
  bool _isDpadLeft(String key) {
    return key.contains('dpad') && key.contains('left') ||
        key == 'dpadleft' ||
        key == 'dpLeft' ||
        key == 'hatswitch' && key.contains('left') ||
        key.contains('pov') && key.contains('left');
  }

  bool _isDpadRight(String key) {
    return key.contains('dpad') && key.contains('right') ||
        key == 'dpadright' ||
        key == 'dpRight' ||
        key.contains('pov') && key.contains('right');
  }

  bool _isDpadUp(String key) {
    return key.contains('dpad') && key.contains('up') ||
        key == 'dpadup' ||
        key == 'dpUp' ||
        key.contains('pov') && key.contains('up');
  }

  bool _isDpadDown(String key) {
    return key.contains('dpad') && key.contains('down') ||
        key == 'dpaddown' ||
        key == 'dpDown' ||
        key.contains('pov') && key.contains('down');
  }

  // Confirm button (A on Xbox, Cross on PlayStation, B on Nintendo)
  bool _isConfirmButton(String key) {
    return key == 'a' ||
        key == 'button a' ||
        key == 'cross' ||
        key == 'button 0' ||
        key == 'button0' ||
        key == 'buttona';
  }

  // Back button (B on Xbox, Circle on PlayStation, A on Nintendo)
  bool _isBackButton(String key) {
    return key == 'b' ||
        key == 'button b' ||
        key == 'circle' ||
        key == 'button 1' ||
        key == 'button1' ||
        key == 'buttonb';
  }

  // Menu/Start button
  bool _isMenuButton(String key) {
    return key == 'start' ||
        key == 'menu' ||
        key == 'options' ||
        key == 'button 7' ||
        key == 'button7' ||
        key.contains('start') ||
        key.contains('menu');
  }

  // Left shoulder button (L1/LB)
  bool _isLeftShoulder(String key) {
    return key == 'l1' ||
        key == 'lb' ||
        key == 'leftshoulder' ||
        key == 'button 4' ||
        key == 'button4' ||
        key.contains('left') && key.contains('shoulder') ||
        key.contains('left') && key.contains('bumper');
  }

  // Right shoulder button (R1/RB)
  bool _isRightShoulder(String key) {
    return key == 'r1' ||
        key == 'rb' ||
        key == 'rightshoulder' ||
        key == 'button 5' ||
        key == 'button5' ||
        key.contains('right') && key.contains('shoulder') ||
        key.contains('right') && key.contains('bumper');
  }

  // Left analog stick X axis
  bool _isLeftStickX(String key) {
    return key == 'leftx' ||
        key == 'left x' ||
        key == 'leftstickx' ||
        key == 'axis 0' ||
        key == 'axis0' ||
        key.contains('left') && key.contains('x');
  }

  // Left analog stick Y axis
  bool _isLeftStickY(String key) {
    return key == 'lefty' ||
        key == 'left y' ||
        key == 'leftsticky' ||
        key == 'axis 1' ||
        key == 'axis1' ||
        key.contains('left') && key.contains('y');
  }

  // Right analog stick X axis
  bool _isRightStickX(String key) {
    return key == 'rightx' ||
        key == 'right x' ||
        key == 'rightstickx' ||
        key == 'axis 2' ||
        key == 'axis2' ||
        key.contains('right') && key.contains('x');
  }

  // Right analog stick Y axis
  bool _isRightStickY(String key) {
    return key == 'righty' ||
        key == 'right y' ||
        key == 'rightsticky' ||
        key == 'axis 3' ||
        key == 'axis3' ||
        key.contains('right') && key.contains('y');
  }

  void _notifyListeners(GamepadAction action) {
    for (final listener in _listeners) {
      listener(action);
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _listeners.clear();
  }
}
