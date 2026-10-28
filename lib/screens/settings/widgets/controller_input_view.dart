import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';

import 'controller_input_state.dart';

/// Adapts hardware input to the render-only controller package.
class ControllerInputView extends StatelessWidget {
  const ControllerInputView({
    super.key,
    required this.inputState,
    required this.controllerType,
  });

  final ControllerInputState inputState;
  final ControllerType controllerType;

  static const _buttons = {
    ButtonId.a: DmControllerButton.south,
    ButtonId.b: DmControllerButton.east,
    ButtonId.x: DmControllerButton.west,
    ButtonId.y: DmControllerButton.north,
    ButtonId.dpadUp: DmControllerButton.dpadUp,
    ButtonId.dpadDown: DmControllerButton.dpadDown,
    ButtonId.dpadLeft: DmControllerButton.dpadLeft,
    ButtonId.dpadRight: DmControllerButton.dpadRight,
    ButtonId.lb: DmControllerButton.leftBumper,
    ButtonId.rb: DmControllerButton.rightBumper,
    ButtonId.lt: DmControllerButton.leftTrigger,
    ButtonId.rt: DmControllerButton.rightTrigger,
    ButtonId.ls: DmControllerButton.leftStick,
    ButtonId.rs: DmControllerButton.rightStick,
    ButtonId.back: DmControllerButton.select,
    ButtonId.start: DmControllerButton.start,
    ButtonId.guide: DmControllerButton.home,
  };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DmControllerView(
        width: 640,
        style: switch (controllerType) {
          ControllerType.playstation => DmControllerStyle.dualSense,
          ControllerType.nintendo => DmControllerStyle.switchPro,
          _ => DmControllerStyle.xbox,
        },
        leftStick: Offset(inputState.leftStickX, inputState.leftStickY),
        rightStick: Offset(inputState.rightStickX, inputState.rightStickY),
        leftTrigger: inputState.leftTrigger,
        rightTrigger: inputState.rightTrigger,
        pressedButtons: {
          for (final entry in _buttons.entries)
            if (inputState.isPressed(entry.key)) entry.value,
          if (inputState.leftTrigger > 0) DmControllerButton.leftTrigger,
          if (inputState.rightTrigger > 0) DmControllerButton.rightTrigger,
        },
      ),
    );
  }
}
