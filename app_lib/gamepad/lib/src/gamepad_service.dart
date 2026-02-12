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

/// Callback type for raw gamepad events (for debugging)
typedef GamepadRawEventCallback =
    void Function(String gamepadId, String key, double value);

/// Simple data class for detected controller info
class DetectedController {
  const DetectedController({required this.id, required this.name});

  final String id;
  final String name;
}

/// Service for handling gamepad input and converting to navigation actions
class GamepadService {
  GamepadService._();

  static final GamepadService _instance = GamepadService._();

  /// Singleton instance
  static GamepadService get instance => _instance;

  StreamSubscription<GamepadEvent>? _subscription;
  final List<GamepadActionCallback> _listeners = [];
  final List<GamepadRawEventCallback> _rawListeners = [];
  final List<VoidCallback> _controllerChangeListeners = [];

  /// Controllers detected from events (more reliable than Gamepads.list())
  final Map<String, DetectedController> _detectedControllers = {};

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

  /// Add a raw event listener (for debugging)
  void addRawListener(GamepadRawEventCallback callback) {
    _rawListeners.add(callback);
  }

  /// Remove a raw event listener
  void removeRawListener(GamepadRawEventCallback callback) {
    _rawListeners.remove(callback);
  }

  /// Add a controller change listener (called when new controller detected)
  void addControllerChangeListener(VoidCallback callback) {
    _controllerChangeListeners.add(callback);
  }

  /// Remove a controller change listener
  void removeControllerChangeListener(VoidCallback callback) {
    _controllerChangeListeners.remove(callback);
  }

  /// Get list of connected gamepads
  /// Combines results from Gamepads.list() with controllers detected from events
  Future<List<DetectedController>> getConnectedGamepads() async {
    final controllers = <String, DetectedController>{};

    // Gamepads.list() may fail on some platforms (e.g. Android where the
    // plugin's `devices` lateinit property is uninitialized until the first
    // input event is received).
    try {
      final listed = await Gamepads.list();
      debugPrint(
        'GamepadService: Gamepads.list() returned ${listed.length} controllers',
      );
      for (final controller in listed) {
        controllers[controller.id] = DetectedController(
          id: controller.id,
          name: controller.name,
        );
      }
    } catch (e) {
      debugPrint('GamepadService: Gamepads.list() failed: $e');
    }

    // Add controllers detected from events (more reliable fallback)
    debugPrint(
      'GamepadService: _detectedControllers has ${_detectedControllers.length} entries',
    );
    for (final entry in _detectedControllers.entries) {
      controllers.putIfAbsent(entry.key, () => entry.value);
    }

    debugPrint(
      'GamepadService: Returning ${controllers.length} total controllers',
    );
    return controllers.values.toList();
  }

  /// Get controllers detected from events only
  List<DetectedController> get detectedControllers =>
      _detectedControllers.values.toList();

  void _handleEvent(GamepadEvent event) {
    // Track controller from event if not already known
    if (!_detectedControllers.containsKey(event.gamepadId)) {
      _detectedControllers[event.gamepadId] = DetectedController(
        id: event.gamepadId,
        name: 'Controller ${event.gamepadId}',
      );
      debugPrint(
        'GamepadService: Detected controller from event: ${event.gamepadId}',
      );
      _notifyControllerChangeListeners();
    }

    // Always notify raw listeners (no debounce for debugging)
    _notifyRawListeners(event.gamepadId, event.key, event.value);

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

    // Determine if button is pressed (Android KEYCODE_ uses inverted values:
    // ACTION_DOWN=0, ACTION_UP=1)
    final isAndroidButton = event.key.startsWith('KEYCODE_');
    final buttonPressed =
        isAndroidButton ? value < _axisThreshold : value > _axisThreshold;

    // Handle button presses
    if (buttonPressed) {
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

    // Handle D-pad HAT analog axes (Android)
    if (_isDpadHatX(key)) {
      if (value < -_axisThreshold) return GamepadAction.left;
      if (value > _axisThreshold) return GamepadAction.right;
    }
    if (_isDpadHatY(key)) {
      // Inverted by gamepads package: positive = up
      if (value > _axisThreshold) return GamepadAction.up;
      if (value < -_axisThreshold) return GamepadAction.down;
    }

    return null;
  }

  // ── D-pad detection ──

  bool _isDpadLeft(String key) {
    return key == 'keycode_dpad_left' ||
        (key.contains('dpad') && key.contains('left')) ||
        key == 'dpadleft' ||
        (key.contains('pov') && key.contains('left'));
  }

  bool _isDpadRight(String key) {
    return key == 'keycode_dpad_right' ||
        (key.contains('dpad') && key.contains('right')) ||
        key == 'dpadright' ||
        (key.contains('pov') && key.contains('right'));
  }

  bool _isDpadUp(String key) {
    return key == 'keycode_dpad_up' ||
        (key.contains('dpad') && key.contains('up')) ||
        key == 'dpadup' ||
        (key.contains('pov') && key.contains('up'));
  }

  bool _isDpadDown(String key) {
    return key == 'keycode_dpad_down' ||
        (key.contains('dpad') && key.contains('down')) ||
        key == 'dpaddown' ||
        (key.contains('pov') && key.contains('down'));
  }

  bool _isDpadHatX(String key) => key == 'axis_hat_x';
  bool _isDpadHatY(String key) => key == 'axis_hat_y';

  // ── Confirm button (A on Xbox, Cross on PlayStation) ──

  bool _isConfirmButton(String key) {
    return key == 'keycode_button_a' ||
        key == 'a' ||
        key == 'button a' ||
        key == 'cross' ||
        key == 'button 0' ||
        key == 'button0' ||
        key == 'buttona';
  }

  // ── Back button (B on Xbox, Circle on PlayStation) ──

  bool _isBackButton(String key) {
    return key == 'keycode_button_b' ||
        key == 'b' ||
        key == 'button b' ||
        key == 'circle' ||
        key == 'button 1' ||
        key == 'button1' ||
        key == 'buttonb';
  }

  // ── Menu/Start button ──

  bool _isMenuButton(String key) {
    return key == 'keycode_button_start' ||
        key == 'start' ||
        key == 'menu' ||
        key == 'options' ||
        key == 'button 9' ||
        key == 'button9';
  }

  // ── Left shoulder button (L1/LB) ──

  bool _isLeftShoulder(String key) {
    return key == 'keycode_button_l1' ||
        key == 'l1' ||
        key == 'lb' ||
        key == 'leftshoulder' ||
        key == 'button 4' ||
        key == 'button4';
  }

  // ── Right shoulder button (R1/RB) ──

  bool _isRightShoulder(String key) {
    return key == 'keycode_button_r1' ||
        key == 'r1' ||
        key == 'rb' ||
        key == 'rightshoulder' ||
        key == 'button 5' ||
        key == 'button5';
  }

  // ── Analog stick axes ──

  bool _isLeftStickX(String key) {
    return key == 'axis_x' ||
        key == 'leftx' ||
        key == 'left x' ||
        key == 'leftstickx' ||
        key == 'axis 0' ||
        key == 'axis0' ||
        key == 'analog 0' ||
        key == 'analog0';
  }

  bool _isLeftStickY(String key) {
    return key == 'axis_y' ||
        key == 'lefty' ||
        key == 'left y' ||
        key == 'leftsticky' ||
        key == 'axis 1' ||
        key == 'axis1' ||
        key == 'analog 1' ||
        key == 'analog1';
  }

  bool _isRightStickX(String key) {
    return key == 'axis_z' ||
        key == 'rightx' ||
        key == 'right x' ||
        key == 'rightstickx' ||
        key == 'axis 2' ||
        key == 'axis2' ||
        key == 'analog 2' ||
        key == 'analog2';
  }

  bool _isRightStickY(String key) {
    return key == 'axis_rz' ||
        key == 'righty' ||
        key == 'right y' ||
        key == 'rightsticky' ||
        key == 'axis 3' ||
        key == 'axis3' ||
        key == 'analog 3' ||
        key == 'analog3';
  }

  void _notifyListeners(GamepadAction action) {
    for (final listener in _listeners) {
      listener(action);
    }
  }

  void _notifyRawListeners(String gamepadId, String key, double value) {
    for (final listener in _rawListeners) {
      listener(gamepadId, key, value);
    }
  }

  void _notifyControllerChangeListeners() {
    debugPrint(
      'GamepadService: Notifying ${_controllerChangeListeners.length} controller change listeners',
    );
    for (final listener in _controllerChangeListeners) {
      listener();
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _listeners.clear();
    _rawListeners.clear();
    _controllerChangeListeners.clear();
    _detectedControllers.clear();
  }
}
