import 'package:app_feedback/app_feedback.dart';
import 'package:app_locale/app_locale.dart' show AppLocale;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showSnackbar', () {
    testWidgets('displays message widget', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showSnackbar(
                      context: context,
                      message: const Text('Test message'),
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
      await tester.pump();
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (
      WidgetTester tester,
    ) async {
      const Key tapTarget = Key('tap-target');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showSnackbar(
                      context: context,
                      message: const Text('Message'),
                      actionLabel: 'ACTION',
                      onActionPressed: () {},
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
      await tester.pump();

      // Verify action button is displayed
      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(find.text('ACTION'), findsOneWidget);
    });
  });

  group('showUndoSnackbar', () {
    testWidgets('displays message and undo button', (
      WidgetTester tester,
    ) async {
      const Key tapTarget = Key('tap-target');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    showUndoSnackbar(
                      context: context,
                      message: const Text('Item deleted'),
                      onUndoPressed: () {},
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
      await tester.pump();

      expect(find.text('Item deleted'), findsOneWidget);
      // Verify undo action button exists
      expect(find.byType(SnackBarAction), findsOneWidget);
    });
  });
}
