import 'package:app_feedback/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showFullScreenDialog', () {
    testWidgets('displays title and content', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showFullScreenDialog(
                  context: context,
                  title: const Text('Full Screen Title'),
                  builder: (context) => const Center(
                    child: Text('Full Screen Content'),
                  ),
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
      await tester.pumpAndSettle();

      expect(find.text('Full Screen Title'), findsOneWidget);
      expect(find.text('Full Screen Content'), findsOneWidget);
    });

    testWidgets('shows close button in app bar', (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showFullScreenDialog(
                  context: context,
                  title: const Text('Title'),
                  builder: (context) => const Text('Content'),
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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('closes when close button pressed',
        (WidgetTester tester) async {
      const Key tapTarget = Key('tap-target');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                showFullScreenDialog(
                  context: context,
                  title: const Text('Title'),
                  builder: (context) => const Text('Content'),
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
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsNothing);
    });
  });
}
