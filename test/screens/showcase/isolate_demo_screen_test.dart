import 'package:app_locale/app_locale.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/app.dart';
import 'package:flutter_app_template/router.dart';
import 'package:flutter_app_template/screens/showcase/isolate_demo_screen.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:isolate_orchestrator/isolate_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DmThemeBloc themeBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    themeBloc = DmThemeBloc(prefs: prefs);
  });

  tearDown(() {
    themeBloc.close();
  });

  test('isolate demo is registered beneath Showcase', () {
    final showcase = AppRouter.routes.singleWhere(
      (route) => route.name == ShowcaseScreen.name,
    );
    final route = showcase.routes.whereType<GoRoute>().singleWhere(
      (route) => route.name == IsolateDemoScreen.name,
    );
    expect(route.path, 'isolate');
  });

  testWidgets(
    'renders IsolateDemoScreen with DuskMoon charts and interactive controls',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: const IsolateDemoScreen(autoStartCluster: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title, Mermaid DAG flowchart, InteractiveViewer zoom, and DuskMoon charts are rendered
      expect(find.text('Isolate Orchestrator'), findsOneWidget);
      expect(find.byType(DmMermaidView), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(DmVizNetworkGraph), findsOneWidget);
      expect(find.byType(Scrollbar), findsWidgets);
      expect(find.text('横向滚动 (Scroll)'), findsOneWidget);
      expect(find.text('自适应画布 (Fit)'), findsOneWidget);

      // Test Mermaid Zoom In
      expect(find.byTooltip('放大 (Zoom In)'), findsWidgets);
      await tester.tap(find.byTooltip('放大 (Zoom In)').first);
      await tester.pumpAndSettle();

      // Toggle between Auto-fit mode and Scrollable mode
      await tester.tap(find.text('自适应画布 (Fit)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('横向滚动 (Scroll)'));
      await tester.pumpAndSettle();

      // 1. Create a new dynamic isolate with custom name into the supervision tree
      final nameField = find.byKey(const ValueKey('new-isolate-name-input'));
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'custom_worker');
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const ValueKey('spawn-dynamic-isolate-btn'));
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('custom_worker'), findsWidgets);

      // 2. Send data across the multi-isolate pipeline and verify final output
      final pipelineInput = find.byKey(const ValueKey('pipeline-input-field'));
      await tester.ensureVisible(pipelineInput);
      await tester.enterText(pipelineInput, 'order-99');
      await tester.pumpAndSettle();

      final sendPipelineBtn = find.byKey(
        const ValueKey('send-pipeline-data-btn'),
      );
      await tester.ensureVisible(sendPipelineBtn);
      await tester.tap(sendPipelineBtn);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pipeline-final-output-text')),
        findsOneWidget,
      );
      expect(find.textContaining('ORDER-99'), findsWidgets);

      // 3. Test inspector RPC call and Supervisor auto-respawn on crash
      final rpcBtn = find.byKey(const ValueKey('inspector-rpc-call-btn'));
      await tester.ensureVisible(rpcBtn);
      await tester.tap(rpcBtn);
      await tester.pumpAndSettle();

      final crashBtn = find.byKey(const ValueKey('inspector-crash-btn'));
      await tester.ensureVisible(crashBtn);
      await tester.tap(crashBtn);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('supervisor-recovery-summary')),
        findsOneWidget,
      );

      // 4. Scroll down to verify DmVizBarChart, Pool creation, and Poolboy DmVizLineChart
      final poolCard = find.byKey(const ValueKey('poolboy-chart-card'));
      await tester.scrollUntilVisible(
        poolCard,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DmVizBarChart), findsWidgets);
      expect(find.byType(DmVizLineChart), findsOneWidget);

      final createPoolBtn = find.byKey(const ValueKey('create-pool-btn'));
      await tester.ensureVisible(createPoolBtn);
      await tester.tap(createPoolBtn);
      await tester.pumpAndSettle();

      // Trigger Poolboy burst overflow
      final burstBtn = find.byKey(const ValueKey('pool-burst-btn'));
      await tester.ensureVisible(burstBtn);
      await tester.tap(burstBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pool-output-summary')), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'full App boots without Provider/InheritedWidget error and navigates to IsolateDemoScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const channel = MethodChannel('xyz.luan/gamepads');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => <dynamic>[]);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      AppRouter.router = GoRouter(
        navigatorKey: AppRouter.key,
        initialLocation: '/home',
        routes: AppRouter.routes,
      );
      await tester.pumpWidget(
        BlocProvider<DmThemeBloc>.value(value: themeBloc, child: const App()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify full App (HomeScreen + AppAdaptiveScaffold + NavigationBloc) built cleanly
      expect(tester.takeException(), isNull);

      // Navigate to /showcase/isolate via GoRouter
      AppRouter.router.go('/showcase/isolate');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(IsolateDemoScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  test(
    'showcaseIsolateEntryPoint executes real OS isolates for P2P pipeline, Supervisor auto-respawn, and Poolboy',
    () async {
      final hub = IsolateHub(
        config: const HubConfig(
          healthCheckInterval: Duration(seconds: 10),
          restartPolicy: RestartPolicy(
            maxAttempts: 5,
            initialDelay: Duration(milliseconds: 20),
          ),
        ),
      );
      await hub.start();
      try {
        final pipelineGroup = await hub.createGroup(
          name: 'pipeline',
          strategy: SupervisionStrategy.oneForOne,
          intensity: const RestartIntensity(
            maxRestarts: 5,
            withinDuration: Duration(seconds: 10),
            backoffPolicy: RestartPolicy(
              initialDelay: Duration(milliseconds: 20),
            ),
          ),
        );
        final ingressHandle = await pipelineGroup.registerService(
          const ChildSpec(
            name: 'ingress',
            role: 'gateway',
            restartType: ChildRestartType.permanent,
            entryPoint: showcaseIsolateEntryPoint,
          ),
        );
        await pipelineGroup.registerService(
          const ChildSpec(
            name: 'transform',
            role: 'processor',
            restartType: ChildRestartType.permanent,
            entryPoint: showcaseIsolateEntryPoint,
          ),
        );

        final storageGroup = await hub.createGroup(
          name: 'storage',
          strategy: SupervisionStrategy.restForOne,
        );
        await storageGroup.registerService(
          const ChildSpec(
            name: 'cache',
            role: 'cache',
            restartType: ChildRestartType.transient,
            entryPoint: showcaseIsolateEntryPoint,
          ),
        );

        // 1. Cross-isolate P2P pipeline hop: / -> /pipeline/ingress -> /pipeline/transform -> /storage/cache
        final pipelineRes = await hub.call<Map<dynamic, dynamic>>(
          '/pipeline/ingress',
          {
            'op': 'pipeline_hop',
            'data': 'hello-isolate',
            'targets': ['/pipeline/transform', '/storage/cache'],
            'hops': <Map<String, dynamic>>[],
          },
        );
        expect(
          pipelineRes['finalOutput'].toString(),
          contains('HELLO-ISOLATE'),
        );
        expect((pipelineRes['hops'] as List).length, 3);

        // 2. Crash /pipeline/ingress and verify Supervisor auto-respawns with a new Isolate ID
        final oldId = ingressHandle.handle?.id;
        final restartedFuture = hub.events
            .where((e) => e is SupervisorChildRestarted)
            .cast<SupervisorChildRestarted>()
            .first;
        final readyFuture = hub.events
            .where(
              (e) => e is IsolateReady && e.handle.path == '/pipeline/ingress',
            )
            .cast<IsolateReady>()
            .first;
        hub.cast('/pipeline/ingress', 'crash');
        final restartEvent = await restartedFuture.timeout(
          const Duration(seconds: 5),
        );
        expect(restartEvent.childPath, '/pipeline/ingress');
        final readyEvent = await readyFuture.timeout(
          const Duration(seconds: 5),
        );
        expect(readyEvent.handle.id, isNot(equals(oldId)));

        // 3. IsolatePool with Poolboy transaction & burst overflow
        final pool = IsolatePool<Map<String, dynamic>>(
          hub: hub,
          config: const IsolatePoolConfig(
            size: 2,
            maxOverflow: 2,
            strategy: PoolStrategy.lifo,
          ),
          workerEntryPoint: showcaseIsolateEntryPoint,
        );
        await pool.start();
        final burstResults = await Future.wait(
          List.generate(
            4,
            (i) => pool.transaction(
              (w) => w.execute({'value': i + 1, 'delayMs': 40}),
            ),
          ),
        );
        expect(burstResults.length, 4);
        await pool.stop();
      } finally {
        await hub.stop();
      }
    },
  );
}
