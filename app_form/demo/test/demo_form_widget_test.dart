import 'package:demo_form/demo_form.dart';
import 'package:duskmoon_widgets/duskmoon_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 800.0]) {
    testWidgets('markdown field lays out and previews at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DemoFormWidget())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final markdown = find.byType(DmMarkdownInput);
      await tester.ensureVisible(markdown);
      await tester.pumpAndSettle();
      expect(tester.getSize(markdown).height, greaterThan(0));
      expect(tester.getSize(markdown).height, lessThanOrEqualTo(400));

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(markdown, findsOneWidget);

      await tester.tap(find.text('Write'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
