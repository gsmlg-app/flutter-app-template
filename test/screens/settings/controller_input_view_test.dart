import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/settings/widgets/controller_input_state.dart';
import 'package:flutter_app_template/screens/settings/widgets/controller_input_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';

void main() {
  testWidgets('maps controller types to the supplied designs', (tester) async {
    for (final entry in {
      ControllerType.xbox: DmControllerStyle.xbox,
      ControllerType.playstation: DmControllerStyle.dualSense,
      ControllerType.nintendo: DmControllerStyle.switchPro,
      ControllerType.generic: DmControllerStyle.xbox,
      ControllerType.unknown: DmControllerStyle.xbox,
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: ControllerInputView(
            inputState: const ControllerInputState(),
            controllerType: entry.key,
          ),
        ),
      );
      expect(
        tester.widget<DmControllerView>(find.byType(DmControllerView)).style,
        entry.value,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('maps hardware buttons and analog triggers without local input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerInputView(
          inputState: ControllerInputState(
            pressedButtons: {
              ButtonId.a,
              ButtonId.dpadUp,
              ButtonId.lb,
              ButtonId.ls,
              ButtonId.start,
              ButtonId.back,
              ButtonId.guide,
            },
            leftStickX: -.75,
            leftStickY: .25,
            rightStickX: .5,
            rightStickY: -1,
            leftTrigger: .5,
            rightTrigger: 1,
          ),
          controllerType: ControllerType.playstation,
        ),
      ),
    );
    final view = tester.widget<DmControllerView>(find.byType(DmControllerView));
    expect(view.leftStick, const Offset(-.75, .25));
    expect(view.rightStick, const Offset(.5, -1));
    expect(view.leftTrigger, .5);
    expect(view.rightTrigger, 1);
    expect(view.pressedButtons, {
      DmControllerButton.south,
      DmControllerButton.dpadUp,
      DmControllerButton.leftBumper,
      DmControllerButton.leftStick,
      DmControllerButton.start,
      DmControllerButton.select,
      DmControllerButton.home,
      DmControllerButton.leftTrigger,
      DmControllerButton.rightTrigger,
    });
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(
                  of: find.byType(DmControllerView),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ControllerInputView(
          inputState: ControllerInputState(),
          controllerType: ControllerType.playstation,
        ),
      ),
    );
    expect(
      tester
          .widget<DmControllerView>(find.byType(DmControllerView))
          .pressedButtons,
      isEmpty,
    );
  });
}
