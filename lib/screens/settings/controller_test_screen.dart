import 'package:app_gamepad/app_gamepad.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_app_template/screens/settings/widgets/controller_input_state.dart';
import 'package:flutter_app_template/screens/settings/widgets/stick_visualizer.dart';
import 'package:flutter_app_template/screens/settings/widgets/trigger_bar.dart';
import 'package:flutter_app_template/screens/settings/widgets/xbox_controller_painter.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';

class ControllerTestScreen extends StatefulWidget {
  static const name = 'Controller Test';
  static const path = 'test';

  const ControllerTestScreen({super.key});

  @override
  State<ControllerTestScreen> createState() => _ControllerTestScreenState();
}

class _ControllerTestScreenState extends State<ControllerTestScreen>
    with SingleTickerProviderStateMixin {
  final GamepadService _gamepadService = GamepadService.instance;

  late final GamepadBloc _gamepadBloc;
  late Ticker _ticker;
  ControllerInputState _inputState = const ControllerInputState();
  ControllerInputState _displayState = const ControllerInputState();
  bool _dirty = false;

  double _deadzone = 0.2;
  bool _showRawData = false;
  List<_RawEvent> _rawLog = [];
  List<_RawEvent> _pendingRawLog = [];
  static const _maxRawLog = 30;

  @override
  void initState() {
    super.initState();
    _gamepadBloc = context.read<GamepadBloc>();
    _gamepadService.addRawListener(_handleRawEvent);
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gamepadBloc.add(const GamepadEnterTestMode());
      _deadzone = _gamepadBloc.state.config.deadzone;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _gamepadService.removeRawListener(_handleRawEvent);
    _gamepadBloc.add(const GamepadExitTestMode());
    super.dispose();
  }

  void _handleRawEvent(String gamepadId, String key, double value) {
    _inputState = accumulateRawEvent(_inputState, key, value);
    _dirty = true;

    if (_showRawData) {
      _pendingRawLog.insert(0, _RawEvent(key: key, value: value));
      if (_pendingRawLog.length > _maxRawLog) {
        _pendingRawLog = _pendingRawLog.sublist(0, _maxRawLog);
      }
    }
  }

  void _onTick(Duration _) {
    if (_dirty) {
      setState(() {
        _displayState = _inputState;
        if (_showRawData && _pendingRawLog.isNotEmpty) {
          _rawLog = List.of(_pendingRawLog);
        }
        _dirty = false;
      });
    }
  }

  ControllerType _controllerTypeFrom(GamepadState gamepadState) {
    final controllers = gamepadState.connectedControllers;
    if (controllers.isEmpty) {
      return ControllerType.unknown;
    }
    return controllers.first.type;
  }

  @override
  Widget build(BuildContext context) {
    return DmAdaptiveScaffold(
      internalAnimations: false,
      selectedIndex: Destinations.indexOf(
        const Key(SettingsScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) =>
          Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: BlocBuilder<GamepadBloc, GamepadState>(
            buildWhen: (prev, curr) =>
                prev.connectedControllers != curr.connectedControllers,
            builder: (context, gamepadState) {
              final hasController = gamepadState.hasController;
              final controllerType = _controllerTypeFrom(gamepadState);
              final isPS = controllerType == ControllerType.playstation;
              final labelType = isPS
                  ? ControllerType.playstation
                  : ControllerType.xbox;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: Text(context.l10n.controllerTest),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),
                        // ── Controller Schematic ──
                        _buildSchematic(hasController, isPS),

                        const SizedBox(height: 16),

                        // ── Triggers ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TriggerBar(
                              value: _displayState.leftTrigger,
                              label: buttonLabel(ButtonId.lt, labelType),
                            ),
                            TriggerBar(
                              value: _displayState.rightTrigger,
                              label: buttonLabel(ButtonId.rt, labelType),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Sticks ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StickVisualizer(
                              x: _displayState.leftStickX,
                              y: _displayState.leftStickY,
                              label: buttonLabel(ButtonId.ls, labelType),
                              isPressed:
                                  _displayState.isPressed(ButtonId.ls),
                              deadzone: _deadzone,
                            ),
                            StickVisualizer(
                              x: _displayState.rightStickX,
                              y: _displayState.rightStickY,
                              label: buttonLabel(ButtonId.rs, labelType),
                              isPressed:
                                  _displayState.isPressed(ButtonId.rs),
                              deadzone: _deadzone,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Deadzone Slider ──
                        _buildDeadzoneSlider(),

                        const Divider(height: 32),

                        // ── Raw Data Toggle ──
                        _buildRawDataSection(),

                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSchematic(bool hasController, bool isPS) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.4,
          child: CustomPaint(
            painter: XboxControllerPainter(
              inputState: _displayState,
              colorScheme: Theme.of(context).colorScheme,
              isPlayStation: isPS,
              dimmed: !hasController,
            ),
            size: Size.infinite,
          ),
        ),
        if (!hasController)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withAlpha(200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Text(
              context.l10n.noControllerDetected,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeadzoneSlider() {
    return Row(
      children: [
        const Icon(Icons.tune, size: 20),
        const SizedBox(width: 8),
        Text(
          context.l10n.analogDeadzone,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Expanded(
          child: DmSlider(
            value: _deadzone,
            min: 0,
            max: 0.5,
            divisions: 10,
            onChanged: (v) {
              setState(() => _deadzone = v);
              final newConfig =
                  _gamepadBloc.state.config.copyWith(deadzone: v);
              _gamepadBloc.add(GamepadUpdateConfig(newConfig));
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(_deadzone * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            _showRawData = !_showRawData;
            if (!_showRawData) {
              _rawLog = [];
              _pendingRawLog = [];
            }
          }),
          child: Row(
            children: [
              Icon(
                _showRawData
                    ? Icons.expand_less
                    : Icons.expand_more,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.showRawData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_showRawData) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: _rawLog.isEmpty
                ? Center(
                    child: Text(
                      'Press buttons on your controller...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _rawLog.length,
                    itemBuilder: (context, i) {
                      final e = _rawLog[i];
                      final colorScheme = Theme.of(context).colorScheme;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Container(
                              width: 140,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              height: 10,
                              child: _ValueBar(
                                value: e.value,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.value.toStringAsFixed(3),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _RawEvent {
  const _RawEvent({required this.key, required this.value});
  final String key;
  final double value;
}

class _ValueBar extends StatelessWidget {
  const _ValueBar({required this.value, required this.colorScheme});
  final double value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: value.abs().clamp(0, 1),
          alignment:
              value >= 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            decoration: BoxDecoration(
              color: value.abs() > 0.5
                  ? colorScheme.primary
                  : colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
