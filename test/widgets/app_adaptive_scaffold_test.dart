import 'package:app_locale/app_locale.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/screens/home/home_screen.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_app_template/widgets/app_adaptive_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_bloc/nav_bloc.dart';

void main() {
  testWidgets('rail preference survives navigation and narrow layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<NavigatorState>();
    final bloc = NavigationBloc(navigatorKey: key, destinations: const []);
    final router = GoRouter(
      navigatorKey: key,
      initialLocation: HomeScreen.path,
      routes: [
        GoRoute(
          path: HomeScreen.path,
          name: HomeScreen.name,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: ShowcaseScreen.path,
          name: ShowcaseScreen.name,
          builder: (context, state) => const ShowcaseScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
    final expandedWidth = tester.getSize(find.byType(NavigationRail)).width;
    await tester.tap(find.byTooltip('Collapse navigation'));
    await tester.pumpAndSettle();
    expect(bloc.state.isNavigationExtended, isFalse);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
    expect(
      tester.getSize(find.byType(NavigationRail)).width,
      lessThan(expandedWidth),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byIcon(Icons.widgets_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShowcaseScreen), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );

    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Expand navigation'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
    await tester.tap(find.byTooltip('Expand navigation'));
    await tester.pumpAndSettle();
    expect(bloc.state.isNavigationExtended, isTrue);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'standalone rail keeps body input while collapsing and expanding',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveScaffold(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            selectedIndex: 0,
            onSelectedIndexChange: (_) {},
            body: (context) => const Padding(
              padding: EdgeInsets.all(16),
              child: TextField(key: ValueKey('body-input')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'keep my input');
      final input = tester.state(find.byType(TextField));
      for (final tooltip in ['Collapse navigation', 'Expand navigation']) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        expect(find.text('keep my input'), findsOneWidget);
        expect(tester.state(find.byType(TextField)), same(input));
      }
      expect(tester.takeException(), isNull);
    },
  );
}
