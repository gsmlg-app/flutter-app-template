import 'package:flutter_app_template/widgets/app_adaptive_scaffold.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

/// Interactive showcase for the three supplied controller designs.
class ControllerViewDemoScreen extends StatefulWidget {
  const ControllerViewDemoScreen({super.key});

  static const name = 'controller-view-demo';
  static const path = 'controller-view';

  @override
  State<ControllerViewDemoScreen> createState() =>
      _ControllerViewDemoScreenState();
}

class _ControllerViewDemoScreenState extends State<ControllerViewDemoScreen> {
  final _events = <String>[];
  final _hiddenTriggerIndicators = <DmControllerStyle>{};
  final _sticks = <(DmControllerStyle, bool), Offset>{};
  final _triggers = <(DmControllerStyle, bool), double>{};

  String _readout(DmControllerStyle style, bool left) {
    final stick = _sticks[(style, left)] ?? Offset.zero;
    final trigger = _triggers[(style, left)] ?? 0;
    return '${left ? "L" : "R"}: X ${stick.dx.toStringAsFixed(2)}  '
        'Y ${stick.dy.toStringAsFixed(2)}  Trigger ${(trigger * 100).round()}%';
  }

  void _onChanged(
    DmControllerStyle style,
    DmControllerButton button,
    bool pressed,
  ) {
    setState(() {
      _events.insert(
        0,
        '${style.name}: ${button.name} ${pressed ? 'down' : 'up'}',
      );
      if (_events.length > 8) _events.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      internalAnimations: false,
      selectedIndex: Destinations.indexOf(
        const Key(ShowcaseScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(title: Text('Controller Views')),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Drag sticks in any direction. Hold Xbox/PS5 triggers to increase travel; release to decrease. Full travel takes 1 second each way.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final style in DmControllerStyle.values)
                    _buildControllerSection(context, style),
                  Text(
                    'Button events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final event in _events) Text(event),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerSection(
    BuildContext context,
    DmControllerStyle style,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.outlined(
      key: ValueKey('${style.name}-section'),
      margin: const EdgeInsets.only(bottom: 24),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(switch (style) {
              DmControllerStyle.xbox => 'Xbox',
              DmControllerStyle.dualSense => 'PlayStation 5',
              DmControllerStyle.switchPro => 'Nintendo Switch Pro',
            }, style: theme.textTheme.titleLarge),
            if (style != DmControllerStyle.switchPro)
              Row(
                children: [
                  const Expanded(child: Text('Trigger indicators')),
                  Switch(
                    key: ValueKey('${style.name}-trigger-indicators-toggle'),
                    value: !_hiddenTriggerIndicators.contains(style),
                    onChanged: (visible) => setState(() {
                      if (visible) {
                        _hiddenTriggerIndicators.remove(style);
                      } else {
                        _hiddenTriggerIndicators.add(style);
                      }
                    }),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Center(
              child: DmControllerView(
                style: style,
                showTriggerIndicators: !_hiddenTriggerIndicators.contains(
                  style,
                ),
                onLeftStickChanged: (value) =>
                    setState(() => _sticks[(style, true)] = value),
                onRightStickChanged: (value) =>
                    setState(() => _sticks[(style, false)] = value),
                onLeftTriggerChanged: (value) =>
                    setState(() => _triggers[(style, true)] = value),
                onRightTriggerChanged: (value) =>
                    setState(() => _triggers[(style, false)] = value),
                onPressedChanged: (button, pressed) =>
                    _onChanged(style, button, pressed),
              ),
            ),
            const SizedBox(height: 16),
            Text(_readout(style, true), style: theme.textTheme.bodyMedium),
            Text(_readout(style, false), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
