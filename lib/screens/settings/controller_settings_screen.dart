import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/settings/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:settings_ui/settings_ui.dart';

class ControllerSettingsScreen extends StatelessWidget {
  static const name = 'Controller Settings';
  static const path = 'controller';

  const ControllerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(SettingsScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(context.l10n.controllerSettingsTitle)),
              SliverFillRemaining(
                child: BlocBuilder<GamepadBloc, GamepadState>(
                  builder: (context, state) {
                    return SettingsList(
                      sections: [
                        _buildEnableSection(context, state),
                        _buildControllersSection(context, state),
                        _buildButtonMappingSection(context, state),
                        _buildDeadzoneSection(context, state),
                        if (state.lastAction != null)
                          _buildLastInputSection(context, state),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  SettingsSection _buildEnableSection(
    BuildContext context,
    GamepadState state,
  ) {
    return SettingsSection(
      title: Text(context.l10n.controllerSettings),
      tiles: <SettingsTile>[
        SettingsTile.switchTile(
          leading: const Icon(Icons.gamepad),
          title: Text(context.l10n.controllerEnabled),
          description: Text(context.l10n.controllerEnabledDesc),
          initialValue: state.config.enabled,
          onToggle: (value) {
            context.read<GamepadBloc>().add(const GamepadToggleEnabled());
          },
        ),
      ],
    );
  }

  SettingsSection _buildControllersSection(
    BuildContext context,
    GamepadState state,
  ) {
    final controllers = state.connectedControllers;

    return SettingsSection(
      title: Text(context.l10n.connectedControllers),
      tiles: <SettingsTile>[
        if (controllers.isEmpty)
          SettingsTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.noControllersConnected),
          )
        else
          ...controllers.map(
            (controller) => SettingsTile(
              leading: Icon(_getControllerIcon(controller.type)),
              title: Text(controller.name),
              description: Text(controller.type.displayName),
            ),
          ),
        SettingsTile(
          leading: const Icon(Icons.refresh),
          title: Text(context.l10n.refreshControllers),
          onPressed: (context) {
            context.read<GamepadBloc>().add(const GamepadRefreshControllers());
          },
        ),
      ],
    );
  }

  SettingsSection _buildButtonMappingSection(
    BuildContext context,
    GamepadState state,
  ) {
    return SettingsSection(
      title: Text(context.l10n.buttonMapping),
      tiles: <SettingsTile>[
        _buildButtonMappingTile(
          context,
          title: context.l10n.confirmButton,
          currentButton: state.config.confirmButton,
          onChanged: (button) {
            final newConfig = state.config.copyWith(confirmButton: button);
            context.read<GamepadBloc>().add(GamepadUpdateConfig(newConfig));
          },
        ),
        _buildButtonMappingTile(
          context,
          title: context.l10n.backButton,
          currentButton: state.config.backButton,
          onChanged: (button) {
            final newConfig = state.config.copyWith(backButton: button);
            context.read<GamepadBloc>().add(GamepadUpdateConfig(newConfig));
          },
        ),
        _buildButtonMappingTile(
          context,
          title: context.l10n.menuButton,
          currentButton: state.config.menuButton,
          onChanged: (button) {
            final newConfig = state.config.copyWith(menuButton: button);
            context.read<GamepadBloc>().add(GamepadUpdateConfig(newConfig));
          },
        ),
        _buildButtonMappingTile(
          context,
          title: context.l10n.prevTabButton,
          currentButton: state.config.prevTabButton,
          onChanged: (button) {
            final newConfig = state.config.copyWith(prevTabButton: button);
            context.read<GamepadBloc>().add(GamepadUpdateConfig(newConfig));
          },
        ),
        _buildButtonMappingTile(
          context,
          title: context.l10n.nextTabButton,
          currentButton: state.config.nextTabButton,
          onChanged: (button) {
            final newConfig = state.config.copyWith(nextTabButton: button);
            context.read<GamepadBloc>().add(GamepadUpdateConfig(newConfig));
          },
        ),
      ],
    );
  }

  SettingsTile _buildButtonMappingTile(
    BuildContext context, {
    required String title,
    required GamepadButton currentButton,
    required ValueChanged<GamepadButton> onChanged,
  }) {
    return SettingsTile.navigation(
      leading: const Icon(Icons.touch_app),
      title: Text(title),
      value: Text(currentButton.displayName),
      onPressed: (context) {
        _showButtonPickerDialog(context, currentButton, onChanged);
      },
    );
  }

  void _showButtonPickerDialog(
    BuildContext context,
    GamepadButton currentButton,
    ValueChanged<GamepadButton> onChanged,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Button'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: GamepadButton.values.length,
              itemBuilder: (context, index) {
                final button = GamepadButton.values[index];
                return ListTile(
                  leading: button == currentButton
                      ? const Icon(Icons.check, color: Colors.green)
                      : const SizedBox(width: 24),
                  title: Text(button.displayName),
                  onTap: () {
                    onChanged(button);
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  SettingsSection _buildDeadzoneSection(
    BuildContext context,
    GamepadState state,
  ) {
    return SettingsSection(
      title: Text(context.l10n.analogDeadzone),
      tiles: <SettingsTile>[
        SettingsTile(
          leading: const Icon(Icons.tune),
          title: Text(context.l10n.analogDeadzone),
          description: Text('${(state.config.deadzone * 100).toInt()}%'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: state.config.deadzone,
              min: 0.0,
              max: 0.5,
              divisions: 10,
              label: '${(state.config.deadzone * 100).toInt()}%',
              onChanged: (value) {
                final newConfig = state.config.copyWith(deadzone: value);
                context.read<GamepadBloc>().add(GamepadUpdateConfig(newConfig));
              },
            ),
          ),
        ),
      ],
    );
  }

  SettingsSection _buildLastInputSection(
    BuildContext context,
    GamepadState state,
  ) {
    return SettingsSection(
      title: Text(context.l10n.lastInput),
      tiles: <SettingsTile>[
        SettingsTile(
          leading: const Icon(Icons.input),
          title: Text(state.lastAction?.name ?? 'None'),
        ),
      ],
    );
  }

  IconData _getControllerIcon(ControllerType type) {
    switch (type) {
      case ControllerType.xbox:
        return Icons.sports_esports;
      case ControllerType.playstation:
        return Icons.sports_esports;
      case ControllerType.nintendo:
        return Icons.sports_esports;
      case ControllerType.generic:
        return Icons.gamepad;
      case ControllerType.unknown:
        return Icons.device_unknown;
    }
  }
}
