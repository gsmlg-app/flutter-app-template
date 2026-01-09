import 'package:app_feedback/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showSuccessToast', () {
    testWidgets('displays success message', (WidgetTester tester) async {
      const Key tapSuccessTarget = Key('tap-success');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showSuccessToast(
                    context: context, title: 'success', message: 'message');
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
                key: tapSuccessTarget,
              ),
            );
          }),
        ),
      ));

      await tester.tap(find.byKey(tapSuccessTarget), warnIfMissed: false);
      await tester.pump(); // schedule animation
      expect(find.text('success'), findsOneWidget);
      expect(find.text('message'), findsOneWidget);
    });
  });

  group('showErrorToast', () {
    testWidgets('displays error message', (WidgetTester tester) async {
      const Key tapErrorTarget = Key('tap-error');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showErrorToast(
                    context: context, title: 'error', message: 'error message');
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
                key: tapErrorTarget,
              ),
            );
          }),
        ),
      ));

      await tester.tap(find.byKey(tapErrorTarget), warnIfMissed: false);
      await tester.pump(); // schedule animation
      expect(find.text('error'), findsOneWidget);
      expect(find.text('error message'), findsOneWidget);
    });

    testWidgets('shows close icon', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showErrorToast(
                  context: context,
                  title: 'error',
                  message: 'error message',
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }),
        ),
      ));

      await tester.tap(find.byKey(tapTarget), warnIfMissed: false);
      await tester.pump();

      // Close icon should be visible
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('message is selectable text', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      const testMessage = 'This is a selectable error message';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showErrorToast(
                  context: context,
                  title: 'error',
                  message: testMessage,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }),
        ),
      ));

      await tester.tap(find.byKey(tapTarget), warnIfMissed: false);
      await tester.pump();

      // Message should use SelectableText widget
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('does not auto-dismiss after long duration',
        (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showErrorToast(
                  context: context,
                  title: 'error',
                  message: 'error message',
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }),
        ),
      ));

      await tester.tap(find.byKey(tapTarget), warnIfMissed: false);
      await tester.pump();
      expect(find.text('error'), findsOneWidget);

      // Wait a long time - error toast should still be visible
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('error'), findsOneWidget);

      // Even longer
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('error'), findsOneWidget);
    });

    testWidgets('can be dismissed by ScaffoldMessenger',
        (WidgetTester tester) async {
      late ScaffoldMessengerState messengerState;
      const Key tapTarget = Key('tap-target');

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: Builder(builder: (BuildContext context) {
              messengerState = ScaffoldMessenger.of(context);
              return GestureDetector(
                onTap: () {
                  showErrorToast(
                    context: context,
                    title: 'error',
                    message: 'error message',
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  height: 100.0,
                  width: 100.0,
                  key: tapTarget,
                ),
              );
            }),
          );
        }),
      ));

      await tester.tap(find.byKey(tapTarget), warnIfMissed: false);
      await tester.pump();
      expect(find.text('error'), findsOneWidget);

      // Dismiss via ScaffoldMessenger
      messengerState.hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Toast should be dismissed
      expect(find.text('error'), findsNothing);
    });
  });
}
