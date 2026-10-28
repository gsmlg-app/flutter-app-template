import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/router.dart';
import 'package:flutter_app_template/screens/showcase/controller_view_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('controller demo is registered beneath Showcase', () {
    final showcase = AppRouter.routes.singleWhere(
      (route) => route.name == ShowcaseScreen.name,
    );
    final route = showcase.routes.whereType<GoRoute>().singleWhere(
      (route) => route.name == ControllerViewDemoScreen.name,
    );
    expect(route.path, 'controller-view');
  });

  for (final width in [390.0, 1200.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('renders controller demo at $width in ${brightness.name}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final colors = ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: brightness,
        );
        final theme = ThemeData(
          colorScheme: colors,
          appBarTheme: AppBarTheme(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: const ControllerViewDemoScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Controller Views'), findsOneWidget);
        expect(find.byType(SliverAppBar), findsOneWidget);
        expect(find.byType(DmAppBar), findsNothing);
        final appBarSurface = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(AppBar),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(appBarSurface.color, colors.primary);
        expect(
          DefaultTextStyle.of(
            tester.element(find.text('Controller Views')),
          ).style.color,
          colors.onPrimary,
        );
        for (final style in DmControllerStyle.values) {
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('${style.name}-section')),
            300,
            scrollable: find.byType(Scrollable).last,
          );
          final section = tester.widget<Card>(
            find.byKey(ValueKey('${style.name}-section')),
          );
          expect(section.color, colors.surfaceContainerLow);
          expect(
            (section.shape! as RoundedRectangleBorder).side.color,
            colors.outlineVariant,
          );
          expect(
            find.descendant(
              of: find.byKey(ValueKey('${style.name}-section')),
              matching: find.byType(DmControllerView),
            ),
            findsOneWidget,
          );
        }
        final toggle = find.byKey(
          const ValueKey('xbox-trigger-indicators-toggle'),
        );
        await tester.scrollUntilVisible(
          toggle,
          -300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DmControllerView>(find.byType(DmControllerView).first)
              .showTriggerIndicators,
          isFalse,
        );
        expect(
          tester
              .widget<DmControllerView>(find.byType(DmControllerView).at(1))
              .showTriggerIndicators,
          isTrue,
        );
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DmControllerView>(find.byType(DmControllerView).first)
              .showTriggerIndicators,
          isTrue,
        );
        for (final style in DmControllerStyle.values) {
          final target = find.byKey(ValueKey('${style.name}-south'));
          await tester.scrollUntilVisible(
            target,
            300,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        final events = find.text('switchPro: south up');
        await tester.ensureVisible(events);
        await tester.pumpAndSettle();
        expect(events, findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
    }
  }
}
