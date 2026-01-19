import 'package:app_gamepad/app_gamepad.dart';
import 'package:flutter/material.dart';

/// A visual representation of a gamepad controller for debugging input
class GamepadVisualizer extends StatefulWidget {
  const GamepadVisualizer({super.key});

  @override
  State<GamepadVisualizer> createState() => _GamepadVisualizerState();
}

class _GamepadVisualizerState extends State<GamepadVisualizer> {
  final GamepadService _gamepadService = GamepadService.instance;

  // Current state of inputs
  final Map<String, double> _buttonStates = {};
  double _leftStickX = 0;
  double _leftStickY = 0;
  double _rightStickX = 0;
  double _rightStickY = 0;

  // Raw event log for debugging
  final List<_RawEvent> _eventLog = [];
  static const int _maxLogEntries = 20;

  @override
  void initState() {
    super.initState();
    _gamepadService.addRawListener(_handleRawEvent);
  }

  @override
  void dispose() {
    _gamepadService.removeRawListener(_handleRawEvent);
    super.dispose();
  }

  void _handleRawEvent(String gamepadId, String key, double value) {
    setState(() {
      // Update button states
      _buttonStates[key.toLowerCase()] = value;

      // Update analog sticks
      final lowerKey = key.toLowerCase();
      if (_isLeftStickX(lowerKey)) {
        _leftStickX = value;
      } else if (_isLeftStickY(lowerKey)) {
        _leftStickY = value;
      } else if (_isRightStickX(lowerKey)) {
        _rightStickX = value;
      } else if (_isRightStickY(lowerKey)) {
        _rightStickY = value;
      }

      // Add to event log
      _eventLog.insert(0, _RawEvent(key: key, value: value));
      if (_eventLog.length > _maxLogEntries) {
        _eventLog.removeLast();
      }
    });
  }

  bool _isLeftStickX(String key) =>
      key.contains('leftx') ||
      key.contains('left x') ||
      key == 'axis 0' ||
      key == 'axis0';

  bool _isLeftStickY(String key) =>
      key.contains('lefty') ||
      key.contains('left y') ||
      key == 'axis 1' ||
      key == 'axis1';

  bool _isRightStickX(String key) =>
      key.contains('rightx') ||
      key.contains('right x') ||
      key == 'axis 2' ||
      key == 'axis2';

  bool _isRightStickY(String key) =>
      key.contains('righty') ||
      key.contains('right y') ||
      key == 'axis 3' ||
      key == 'axis3';

  bool _isButtonPressed(List<String> keys) {
    for (final key in keys) {
      final value = _buttonStates[key] ?? 0;
      if (value > 0.5) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Controller visualization
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Top row: Shoulder buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShoulderButton('LB', [
                    'l1',
                    'lb',
                    'button 4',
                    'button4',
                  ]),
                  _buildShoulderButton('RB', [
                    'r1',
                    'rb',
                    'button 5',
                    'button5',
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              // Middle row: Sticks and face buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left stick
                  _buildAnalogStick('L', _leftStickX, _leftStickY),
                  // D-pad
                  _buildDpad(),
                  // Face buttons
                  _buildFaceButtons(),
                  // Right stick
                  _buildAnalogStick('R', _rightStickX, _rightStickY),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom row: Start/Select
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallButton('SELECT', [
                    'select',
                    'back',
                    'button 6',
                    'button6',
                  ]),
                  const SizedBox(width: 32),
                  _buildSmallButton('START', [
                    'start',
                    'menu',
                    'button 7',
                    'button7',
                  ]),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Raw event log
        Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Raw Input Log',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _eventLog.clear()),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _eventLog.isEmpty
                    ? Center(
                        child: Text(
                          'Press buttons on your controller...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _eventLog.length,
                        itemBuilder: (context, index) {
                          final event = _eventLog[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event.key,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildValueBar(event.value, colorScheme),
                                const SizedBox(width: 8),
                                Text(
                                  event.value.toStringAsFixed(2),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueBar(double value, ColorScheme colorScheme) {
    return SizedBox(
      width: 60,
      height: 12,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value.abs().clamp(0, 1),
            alignment: value >= 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: value > 0.5
                    ? colorScheme.primary
                    : colorScheme.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoulderButton(String label, List<String> keys) {
    final isPressed = _isButtonPressed(keys);
    return Container(
      width: 60,
      height: 24,
      decoration: BoxDecoration(
        color: isPressed ? Colors.green : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalogStick(String label, double x, double y) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade600, width: 2),
          ),
          child: Stack(
            children: [
              // Stick position indicator
              Positioned(
                left: 30 + (x * 20) - 8,
                top: 30 + (y * 20) - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: (x.abs() > 0.1 || y.abs() > 0.1)
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildDpad() {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          // Up
          Positioned(
            left: 22,
            top: 0,
            child: _buildDpadButton(Icons.arrow_drop_up, [
              'dpadup',
              'dpup',
              'dp up',
            ]),
          ),
          // Down
          Positioned(
            left: 22,
            bottom: 0,
            child: _buildDpadButton(Icons.arrow_drop_down, [
              'dpaddown',
              'dpdown',
              'dp down',
            ]),
          ),
          // Left
          Positioned(
            left: 0,
            top: 22,
            child: _buildDpadButton(Icons.arrow_left, [
              'dpadleft',
              'dpleft',
              'dp left',
            ]),
          ),
          // Right
          Positioned(
            right: 0,
            top: 22,
            child: _buildDpadButton(Icons.arrow_right, [
              'dpadright',
              'dpright',
              'dp right',
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadButton(IconData icon, List<String> keys) {
    final isPressed = _isButtonPressed(keys);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isPressed ? Colors.green : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildFaceButtons() {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          // Y / Triangle (top)
          Positioned(
            left: 22,
            top: 0,
            child: _buildFaceButton('Y', Colors.amber, [
              'y',
              'button 3',
              'button3',
            ]),
          ),
          // A / Cross (bottom)
          Positioned(
            left: 22,
            bottom: 0,
            child: _buildFaceButton('A', Colors.green, [
              'a',
              'button 0',
              'button0',
            ]),
          ),
          // X / Square (left)
          Positioned(
            left: 0,
            top: 22,
            child: _buildFaceButton('X', Colors.blue, [
              'x',
              'button 2',
              'button2',
            ]),
          ),
          // B / Circle (right)
          Positioned(
            right: 0,
            top: 22,
            child: _buildFaceButton('B', Colors.red, [
              'b',
              'button 1',
              'button1',
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceButton(String label, Color color, List<String> keys) {
    final isPressed = _isButtonPressed(keys);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isPressed ? color : Colors.grey.shade700,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(String label, List<String> keys) {
    final isPressed = _isButtonPressed(keys);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPressed ? Colors.green : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RawEvent {
  _RawEvent({required this.key, required this.value});

  final String key;
  final double value;
}
