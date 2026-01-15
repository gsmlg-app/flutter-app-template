import 'package:app_feedback/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showAppDialog', () {
    testWidgets('displays title and content', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showAppDialog(
                      context: context,
                      title: const Text('Dialog Title'),
                      content: const Text('Dialog Content'),
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

      expect(find.text('Dialog Title'), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
    });

    testWidgets('displays action buttons', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showAppDialog(
                      context: context,
                      title: const Text('Confirm'),
                      content: const Text('Are you sure?'),
                      actions: [
                        AppDialogAction(
                          onPressed: (ctx) => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        AppDialogAction(
                          onPressed: (ctx) => Navigator.of(ctx).pop(true),
                          child: const Text('OK'),
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

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('returns result when action pressed', (
      WidgetTester tester,
    ) async {
      const Key tapTarget = Key('tap-target');
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () async {
                    result = await showAppDialog<bool>(
                      context: context,
                      title: const Text('Confirm'),
                      content: const Text('Are you sure?'),
                      actions: [
                        AppDialogAction(
                          onPressed: (ctx) => Navigator.of(ctx).pop(true),
                          child: const Text('Yes'),
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

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('AppDialogAction', () {
    testWidgets('renders as TextButton on Android', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AppDialogAction(
              onPressed: (ctx) {},
              child: const Text('Action'),
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
