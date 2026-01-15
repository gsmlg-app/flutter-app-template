import 'package:app_feedback/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showBottomSheetActionList', () {
    testWidgets('displays action buttons', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showBottomSheetActionList(
                      context: context,
                      actions: [
                        BottomSheetAction(
                          title: const Text('Action 1'),
                          onTap: () {},
                        ),
                        BottomSheetAction(
                          title: const Text('Action 2'),
                          onTap: () {},
                        ),
                      ],
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    height: 100.0,
                    width: 100.0,
                    key: tapTarget,
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(tapTarget), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Action 1'), findsOneWidget);
      expect(find.text('Action 2'), findsOneWidget);
    });

    testWidgets('calls onTap when action pressed', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      var actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showBottomSheetActionList(
                      context: context,
                      actions: [
                        BottomSheetAction(
                          title: const Text('Press Me'),
                          onTap: () => actionPressed = true,
                        ),
                      ],
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    height: 100.0,
                    width: 100.0,
                    key: tapTarget,
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(tapTarget), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      expect(actionPressed, isTrue);
    });
  });

  group('BottomSheetAction', () {
    test('creates action with required parameters', () {
      final action = BottomSheetAction(title: const Text('Test'), onTap: () {});

      expect(action.title, isA<Text>());
      expect(action.style, isNull);
    });

    test('creates action with custom style', () {
      final style = ElevatedButton.styleFrom(backgroundColor: Colors.red);
      final action = BottomSheetAction(
        title: const Text('Test'),
        onTap: () {},
        style: style,
      );

      expect(action.style, equals(style));
    });
  });
}
